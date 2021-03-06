# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # https://github.com/heartcombo/devise/pull/4033/files
  protect_from_forgery with: :exception, prepend: true

  after_action :flash_to_headers
  after_action :update_user_activity

  # this is so that json requests don't redirect without a user
  before_action :authenticate_user!
  # before_action :authenticate_user!, unless: request.format == :json
  # before_action :user_needed, if: request.format == :json

  before_action :set_paper_trail_whodunnit
  before_action :set_global_search_variable

  GIFTABLE_TYPES = {
    'Person' => Person,
    'Invitation' => Invitation
  }.freeze

  REWARDABLE_TYPES = {
    'GiftCard' => GiftCard,
    'CashCard' => CashCard,
    'DigitalGift' => DigitalGift
  }.freeze

  def set_global_search_variable
    @q = Person.ransack(params[:q])
  end

  def user_needed
    unless current_user
      respond_to do |format|
        format.json { render json: { error: 'authentication error' }.to_json, status: :unauthorized }
        format.html do
          flash[:warning] = 'Unathorized'
          redirect_to root_url
        end
        format.any { redirect_to root_url }
      end
    end
  end

  def admin_needed
    unless current_user&.admin?
      respond_to do |format|
        format.json { render json: { error: 'authentication error' }.to_json, status: :unauthorized }
        format.html do
          flash[:warning] = 'Unathorized'
          redirect_to root_url
        end
        format.any { redirect_to root_url }
      end
    end
  end

  delegate :current_cart, to: :current_user

  def update_user_activity
    if current_user.present?
      current_user.last_sign_in_at = Time.current
      current_user.save
    end
    true
  end

  def flash_to_headers
    return unless request.xhr?

    response.headers['X-Message'] = flash_message if flash_message
    response.headers['X-Message-Type'] = flash_type.to_s if flash_type
    flash.discard # don't want the flash to appear when you reload page
  end

  # def after_sign_in_path_for(_resource)
  #   if current_user.sign_in_count == 1
  #     flash[:error] = 'please update your password'
  #     reset_password_users_path
  #   else
  #     root_path
  #   end
  # end

  def route_not_found
    Rails.logger.error "Route not found from #{ip} at #{Time.now.utc.iso8601}"
    render 'error_pages/404', status: :not_found
  end

  private

  def flash_message
    %i[error warning notice].each do |type|
      return flash[type] if flash[type].present?
    end
    nil
  end

  def flash_type
    %i[error warning notice].each do |type|
      return type if flash[type].present?
    end
    nil
  end
end
