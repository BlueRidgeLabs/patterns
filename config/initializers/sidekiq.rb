# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = Redis.current
  config.average_scheduled_poll_interval = 1 # poll every second
end

Sidekiq.configure_client do |config|
  config.redis = Redis.current
end
