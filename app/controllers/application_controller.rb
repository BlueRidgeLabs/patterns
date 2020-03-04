# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  after_action :flash_to_headers
  after_action :update_user_activity

  # this is so that json requests don't redirect without a user
  before_action :authenticate_user!
  # before_action :authenticate_user!, unless: request.format == :json
  # before_action :user_needed, if: request.format == :json

  before_action :set_paper_trail_whodunnit
  before_action :set_global_search_variable

  def set_global_search_variable
    @q = Person.ransack(params[:q])
  end

  def user_needed
    unless current_user
      render json: { "error" => "authentication error" }, status: :unauthorized
    end
  end

  def admin_needed
    unless current_user&.admin?
      flash[:warning] = "Unathorized"
      render json: { "error" => "authentication error" }, status: :unauthorized
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

    response.headers["X-Message"] = flash_message if flash_message
    response.headers["X-Message-Type"] = flash_type.to_s if flash_type
    flash.discard # don't want the flash to appear when you reload page
  end

  def after_sign_in_path_for(_resource)
    if current_user.sign_in_count == 1
      flash[:error] = "please update your password"
      edit_user_registration_path
    else
      root_path
    end
  end

  def route_not_found
    Rails.logger.error "Route not found from #{ip} at #{Time.now.utc.iso8601}"
    render "error_pages/404", status: :not_found
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
