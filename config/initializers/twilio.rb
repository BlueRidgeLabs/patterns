# frozen_string_literal: true

Twilio.configure do |config|
  config.account_sid = Rails.application.credentials.twilio[:account_sid]
  config.auth_token = Rails.application.credentials.twilio[:auth_token]
end
