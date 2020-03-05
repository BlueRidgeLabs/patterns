# frozen_string_literal: true

require 'giftrocket'
Giftrocket.configure do |config|
  config[:access_token] = ENV['GIFTROCKET_API_KEY']
  config[:base_api_uri] = ENV['GIFTROCKET_API_ENDPOINT']
end
