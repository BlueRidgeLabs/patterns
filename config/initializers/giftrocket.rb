# frozen_string_literal: true

require 'giftrocket'
Giftrocket.configure do |config|
  config[:access_token] = Rails.application.credentials.giftrocket[:api_key]
  config[:base_api_uri] = Rails.application.credentials.giftrocket[:api_endpoint]
end
