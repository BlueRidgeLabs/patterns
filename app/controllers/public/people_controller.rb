# frozen_string_literal: true

class Public::PeopleController < ApplicationController
  layout false
  after_action :allow_iframe
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  before_action :find_user, only: %i[api_create show update]
  before_action :find_person, only: %i[show update]

  # GET /people/new
  def new
    # this should only allow permitted domains.
    @referrer = URI(params[:referrer]).to_s if params[:referrer].present?
    @person = ::Person.new
    @person.created_by = current_user.id if current_user.present?
  end

  def show
    render json: @person.to_json
  end

  def update
    if @current_user.present? && @person.present?
      PaperTrail.request.whodunnit = @current_user

      if update_params[:tags].present?
        tags = update_params[:tags]
        tags = tags.tr('_', ' ').split(',')
        @person.tag_list.add(tags)
        @person.save
      end

      if update_params[:note].present?
        Comment.create(content: update_params[:note].tr('_', ' '),
                       user_id: @current_user.id,
                       commentable_type: 'Person',
                       commentable_id: @person.id)
      end

      to_update = update_params.except(:tags, :note)
      @person.update(to_update)

      @person.save
      render json: { success: true }
    else
      render json: { success: false }, status: :not_found
    end
  end

  def api_create
    output = { success: false }
    PaperTrail.request.whodunnit = @current_user
    @person = Person.new(api_create_params.except(:tags, :low_income, :locale_name))
    @person.referred_by = 'created via SMS'
    @person.signup_at = Time.current
    @person.created_by = @current_user.id
    if params[:tags].present?
      tags = api_create_params[:tags].tr('_', ' ').split(',')
      @person.tag_list.add(tags)
    end
    @person.low_income = api_create_params[:low_income] == 'Y' if api_create_params[:low_income].present?

    if api_create_params[:locale_name].present?
      locale = Person.locale_name_to_locale(api_create_params[:locale_name])
      @person.locale = locale if locale.present?
    end
    output[:success] = @person.save ? true : false
    http_code = output[:success] ? 201 : 401
    render json: output, status: http_code
  end

  # POST /people
  # rubocop:disable Metrics/MethodLength
  def create
    @person = ::Person.new(person_params)
    @person.signup_at = Time.current

    success_msg = 'Thanks! We will be in touch soon!'
    error_msg   = "Oops! Looks like something went wrong. Please get in touch with us at <a href='mailto:#{ENV['MAILER_SENDER']}?subject=Patterns sign up problem'>#{ENV['MAILER_SENDER']}</a> to figure it out!"

    @person.tag_list.add(params[:age_range]) if params[:age_range].present?

    if params[:referral].present?
      @person.referred_by = params[:referral][0, 100] # only 100 characters
    end

    @person.created_by = current_user.id if current_user.present?

    @msg = @person.save ? success_msg : error_msg
    respond_to do |format|
      format.html { render action: 'create' }
    end
  end
  # rubocop:enable Metrics/MethodLength

  def deactivate
    @person = Person.find_by(token: d_params[:token])

    if @person && @person.id == d_params[:person_id].to_i
      @person.deactivate!('email')
      @person.save
      ::AdminMailer.deactivate(person: @person).deliver_later
    else
      redirect_to root_path
    end
  end

  private

    def find_user
      raise ActionController::RoutingError.new('Not Found') if request.headers['AUTHORIZATION'].blank?

      @current_user = User.find_by(token: request.headers['AUTHORIZATION'])

      if @current_user.nil?
        render(file: 'public/404.html', status: :not_found) && return
      else
        true
      end
    end

    def find_person
      if update_params[:phone_number].present?
        phone = PhonyRails.normalize_number(CGI.unescape(update_params[:phone_number]))
        @person = Person.find_by(phone_number: phone)
        if @person.nil?
          render(file: 'public/404.html', status: :not_found) && return
        else
          true
        end
      end
    end

    def api_create_params
      params.permit(:tags,
        :first_name,
        :last_name,
        :preferred_contact_method,
        :postal_code,
        :email_address,
        :locale,
        :locale_name,
        :landline,
        :referred_by,
        :note,
        :low_income,
        :phone_number,
        :rapidpro_uuid,
        :verified)
    end

    def update_params
      person_attributes = Person.attribute_names.map(&:to_sym)
      %i[id created_at signup_at updated_at].each do |del|
        person_attributes.delete_at(person_attributes.index(del))
      end
      person_attributes += %i[tags note]
      params.permit(person_attributes)
    end

    def d_params
      params.permit(:person_id, :token)
    end

    # rubocop:disable Metrics/MethodLength
    def person_params
      params.require(:person).permit(:first_name,
        :last_name,
        :email_address,
        :phone_number,
        :preferred_contact_method,
        :low_income,
        :address_1,
        :address_2,
        :locale,
        :locale_name,
        :city,
        :state,
        :postal_code,
        :token,
        :primary_device_id,
        :primary_device_description,
        :secondary_device_id,
        :secondary_device_description,
        :primary_connection_id,
        :primary_connection_description,
        :secondary_connection_id,
        :secondary_connection_description,
        :participation_type,
        :referred_by,
        :tags)
    end
    # rubocop:enable Metrics/MethodLength

    def allow_iframe
      response.headers.except! 'X-Frame-Options'
    end
end
