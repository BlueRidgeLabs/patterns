# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = if ENV['REDIS_URL'].blank?
                   { host: 'localhost', port: 6379, timeout: 2 }
                 else
                   { url: ENV['REDIS_URL'], timeout: 2 }
                 end

  config.average_scheduled_poll_interval = 1 # poll every second
end

Sidekiq.configure_client do |config|
  config.redis = if ENV['REDIS_URL'].blank?
                   { host: 'localhost', port: 6379, timeout: 2 }
                 else
                   { url: ENV['REDIS_URL'], timeout: 2 }
                 end
end
