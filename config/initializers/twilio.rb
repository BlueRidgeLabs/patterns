# frozen_string_literal: true

Twilio.configure do |config|
  config.account_sid = ENV['TWILIO_ACCOUNT_SID']
  config.auth_token = ENV['TWILIO_AUTH_TOKEN']
  # config.account_sid = Rails.application.secrets.twilio_account_sid
  # config.auth_token = Rails.application.secrets.twilio_auth_token
end
