# frozen_string_literal: true

Twilio.configure do |config|
  config.account_sid = Rails.application.credentials.twilio[:account_sid]
  config.auth_token =Rails.application.credentials.twilio[:auth_token]
  # config.account_sid = Rails.application.secrets.twilio_account_sid
  # config.auth_token = Rails.application.secrets.twilio_auth_token
end
