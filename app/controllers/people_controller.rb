# frozen_string_literal: true

# == Schema Information
#
# Table name: people
#
#  id                               :integer          not null, primary key
#  first_name                       :string(255)
#  last_name                        :string(255)
#  email_address                    :string(255)
#  address_1                        :string(255)
#  address_2                        :string(255)
#  city                             :string(255)
#  state                            :string(255)
#  postal_code                      :string(255)
#  geography_id                     :integer
#  primary_device_id                :integer
#  primary_device_description       :string(255)
#  secondary_device_id              :integer
#  secondary_device_description     :string(255)
#  primary_connection_id            :integer
#  primary_connection_description   :string(255)
#  phone_number                     :string(255)
#  participation_type               :string(255)
#  created_at                       :datetime
#  updated_at                       :datetime
#  signup_ip                        :string(255)
#  signup_at                        :datetime
#  voted                            :string(255)
#  called_311                       :string(255)
#  secondary_connection_id          :integer
#  secondary_connection_description :string(255)
#  verified                         :string(255)
#  preferred_contact_method         :string(255)
#  token                            :string(255)
#

# FIXME: Refactor and re-enable cop
# rubocop:disable ClassLength
class PeopleController < ApplicationController

  before_action :set_person, only: %i[show edit update destroy]
  helper_method :sort_column, :sort_direction

  # GET /people
  # GET /people.json

  # rubocop:disable Metrics/AbcSize
  def index
    Person.per_page = params[:per_page] if params[:per_page].present? # allow for larger pages

    # this could be cleaner...
    search = if params[:tags].blank?
               Person.active.includes(:taggings).paginate(page: params[:page]).
                 order(sort_column + ' ' + sort_direction)
             else
               tags =  params[:tags].split(',').map(&:strip)
               @tags = Person.active.tag_counts.where(name: tags)

               Person.active.includes(:taggings).paginate(page: params[:page]).
                 order(sort_column + ' ' + sort_direction).
                 tagged_with(tags)
             end
    # only show verified people to non-admins
    @people = current_user.admin? ? search : search.verified
    @tags ||= []
  end

  def map
    @zips = Person.active.group(:postal_code).size
    @max =  @zips.values.max
  end
  # rubocop:enable Metrics/AbcSize

  # GET /people/1
  # GET /people/1.json
  def show
    @comment = Comment.new commentable: @person

    @last_gift_card = Reward.last # default scope is id: :desc
    @gift_card = Reward.new
    @tags = @person.tags.pluck(:name)
    # @outgoingmessages = TwilioMessage.where(to: @person.normalized_phone_number).limit(10)
    # @twilio_wufoo_formids = @outgoingmessages.distinct.pluck(:wufoo_formid)

    # @allmessages =  TwilioMessage.where('to = :number or from = :number', number: @person.normalized_phone_number)
  end

  # GET /people/new
  def new
    @person ||= Person.new
  end

  # GET /people/1/edit
  def edit; end

  def amount
    @people = Person.order_by_reward_sum.page(params[:page])
  end

  def lookup
    person = Person.find_by(rapidpro_uuid: params[:uuid])
    if person
      redirect_to person_path(person)
    else
      redirect_to root_path
    end
  end

  # POST /people/:person_id/deactivate
  def deactivate
    @person = Person.find_by id: params[:person_id]
    @person.deactivate!('admin_interface')
    flash[:notice] = "#{@person.full_name} deactivated"
    respond_to do |format|
      format.js
      format.html { redirect_to people_path }
    end
  end

  # POST /people/:person_id/deactivate
  def reactivate
    @person = Person.find_by id: params[:person_id], active: false
    if @person.present?
      @person.reactivate!
      flash[:notice] = "#{@person.full_name} re-activated"
      respond_to do |format|
        format.js
        format.html { redirect_to people_path }
      end
    end
  end

  # FIXME: Refactor and re-enable cop
  # TODO: killoff wufoo
  # rubocop:disable Metrics/MethodLength
  #
  # POST /people
  # POST /people.json
  def create
    @person = Person.new(person_params)
    @person.created_by = current_user.id

    if @person.errors.present?
      errors = []
      @person.errors.full_messages.each { |m| errors.push m }
      flash[:error] = errors.join(', ')
    end
    if @person.save
      redirect_to person_path(@person)
    else
      render action: :new, person: @person
    end
  end
  # rubocop:enable Metrics/MethodLength

  # PATCH/PUT /people/1
  # PATCH/PUT /people/1.json
  def update
    respond_to do |format|
      if @person.with_user(current_user).update(person_params)
        format.html { redirect_to @person, notice: 'Person was successfully updated.' }
        format.json { respond_with_bip(@person) }
      else
        flash[:error] = @person.errors.full_messages.join(', ')
        format.html { render action: 'edit' }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.json
  def destroy
    @person.destroy
    respond_to do |format|
      format.html { redirect_to people_url }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_person
      @person = Person.includes(:tags, :taggings).find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    # rubocop:disable Metrics/MethodLength
    def person_params
      params.require(:person).permit(:first_name,
                                     :last_name,
                                     :verified,
                                     :referred_by,
                                     :low_income,
                                     :locale,
                                     :email_address,
                                     :neighborhood,
                                     :address_1,
                                     :address_2,
                                     :city,
                                     :state,
                                     :postal_code,
                                     :geography_id,
                                     :primary_device_id,
                                     :primary_device_description,
                                     :secondary_device_id,
                                     :secondary_device_description,
                                     :primary_connection_id,
                                     :primary_connection_description,
                                     :secondary_connection_id,
                                     :secondary_connection_description,
                                     :phone_number,
                                     :landline,
                                     :participation_type,
                                     :preferred_contact_method,
                                     gift_cards_attributes: %i[
                                       gift_card_number
                                       expiration_date
                                       person_id
                                       notes
                                       created_by
                                       reason
                                       amount
                                       giftable_id
                                       giftable_type
                                     ])
    end
    # rubocop:enable Metrics/MethodLength

    def sort_column
      Person.column_names.include?(params[:sort]) ? params[:sort] : 'people.id'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
    end

end
# rubocop:enable ClassLength
