# frozen_string_literal: true

require 'tremendous'

Tremendous::Client ||= Tremendous::Rest.new(
  Rails.application.credentials.tremendous[:api_token],
  Rails.application.credentials.tremendous[:endpoint]
)

if %w[production staging].include? Rails.env
  raise 'no tremendous webhooks created!' if Tremendous::Client.webhooks.list.empty?
end
