# frozen_string_literal: true

class CartController < ApplicationController
  include ApplicationHelper
  before_action :cart_init, except: %i[change_cart add_user delete_user]
  before_action :type_init

  # Index
  def show
    current_user.current_cart = @cart

    @people = @cart.people
    @users = @cart.users
    @comment = Comment.new commentable: @cart
    @selectable_users = User.approved.where.not(id: @users.pluck(:id))
    respond_to do |format|
      format.html
      format.json { render json: @people.pluck(:id) }
      format.csv do
        if current_user.admin?
          output = CSV.generate do |csv|
            csv << Person.column_names.map(&:titleize)
            @people.each { |person| csv << person.to_a }
          end
          send_data output, filename: "Pool-#{@cart.name}.csv"
        else
          flash[:error] = I18n.t('not_permitted')
        end
      end
    end
  end

  def new
    @cart = Cart.new
  end

  def create
    @cart = Cart.new(cart_params)
    @cart.user_id = current_user.id
    @create_result = @cart.save
    respond_to do |format|
      if @create_result
        format.js {}
        format.json {}
        format.html { redirect_to @cart, notice: 'Pool was successfully created.' }
      else
        flash[:error] = @cart.errors
        format.js {}
        format.html { render action: 'new' }
        format.json { render json: @cart.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @cart.update(cart_update_params)
        format.html { redirect_to cart_path(@cart), notice: 'Cart was successfully updated.' }
        format.json { respond_with_bip(@cart) }
      else
        flash[:error] = @cart.errors
        format.html { render action: 'edit' }
        format.json { render json: @cart.errors, status: :unprocessable_entity }
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def add
    pids = cart_params[:person_id].split('/')
    people = Person.where(id: pids)
    @added = []
    current_size = @cart.people.size
    people.each do |person|
      next if @cart.people.include? person

      @added << person.id
      begin
        @cart.people << person
      rescue ActiveRecord::RecordInvalid => e
        flash[:error] = e.message
      end
    end
    new_size = @cart.people.size
    delta = new_size - current_size
    flash[:notice] = "#{delta} people added to #{@cart.name}" if delta.positive?
    respond_to do |format|
      format.js
      format.json { render json: @cart.people.pluck(:id) }
      format.html { render json: @cart.people.pluck(:id) }
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Delete
  # rubocop:disable Metrics/MethodLength
  def delete
    if cart_params[:person_id].blank?
      @deleted = @cart.people.pluck(:id)
      @cart.people = []
      # callbacks don't happen here, for soem reason.
      @cart.rapidpro_sync = false
      @cart.save
      @deleted_all = true
      flash[:notice] = I18n.t('cart.delete_all_people_success', cart_name: @cart.name)
    else
      @deleted = [cart_params[:person_id]]
      cart_person = @cart.carts_people.find_by(person_id: cart_params[:person_id])
      cart_person.destroy if cart_person.present?
      @deleted_all = @cart.people.empty?
      flash[:notice] = I18n.t('cart.delete_person_success', person_name: cart_person.person.full_name, cart_name: @cart.name)
    end
    @cart.save

    respond_to do |format|
      format.js
      format.json { render json: @cart.to_json }
      format.html { render json: @cart.to_json }
    end
  end
  # rubocop:enable Metrics/MethodLength

  def index
    if current_user.admin?
      current_user.reload
      @carts = Cart.includes(:users, :people)

      respond_to do |format|
        # format.js
        format.json { render json: @carts.to_json }
        format.html
      end
    else
      redirect_to current_cart
    end
  end

  def destroy
    @cart.destroy_all
    flash[:notice] = "#{@cart.name} has been destroyed"
    respond_to do |format|
      format.html { redirect_to :back }
      format.json { head :no_content }
      format.js {}
    end
  end

  def change_cart
    @cart = Cart.find(params[:cart]) || current_cart
    @current_session = ResearchSession.find(params[:current_session_id]) || nil if params[:current_session_id].present?
    current_user.current_cart = @cart
    respond_to do |format|
      format.html { redirect_to cart_path(@cart) }
      format.json do
        render json: { success: true,
                       cart_id: @cart.id,
                       cart_name: cart_name }
      end
      format.js { render layout: false }
    end
  end

  def check_name
    @cart_name_valid = !Cart.where(name: param[:name]).exists?
    status = @cart_name_valid ? 200 : 422
    respond_to do |format|
      format.json do
        render json: { success: @cart_name_valid, valid: @cart_name_valid }, status: status
      end
      format.html render text: @cart_name_valid, status: status
    end
  end

  def add_user
    @cart = Cart.find cart_params[:id]
    @user = User.find(cart_params[:user_id])
    @cart.users << @user unless @cart.users.include? @user
    flash[:error] = @cart.errors if @cart.errors
  end

  def delete_user
    @cart = Cart.find cart_params[:id]
    @deleted = nil
    @user = User.find(cart_params[:user_id])
    if @cart.users.size > 1 && @cart.users.include?(@user)
      @deleted = @cart.users.delete(@user)
      @cart.save
    end

    flash[:error] = "Can't remove user..." if @deleted.nil?
  end

  private

    def cart_update_params
      params.require(:cart).permit(:description,
        :name,
        :id,
        :user_id,
        :user,
        :person,
        :rapidpro_sync,
        :person_id)
    end

    def cart_params
      params.permit(:person_id,
        :all,
        :type,
        :name,
        :id,
        :user,
        :rapidpro_sync,
        :user_id,
        :description,
        :notes)
    end

    def type_init
      # type is if it's mini or not, for views
      @type = cart_params[:type].presence || 'full'
    end

    def cart_init
      if cart_params[:id].present?
        @cart = Cart.find(cart_params[:id])
        current_user.current_cart = @cart
      else
        @cart = current_user.current_cart
      end
    end
end
