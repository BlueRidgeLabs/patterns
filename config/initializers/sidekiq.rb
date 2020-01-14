# frozen_string_literal: true

redis_conn = proc {
  Redis.current # do anything you want here
}

threads_count = ENV.fetch('RAILS_MAX_THREADS') { 25 }

Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: threads_count.to_i + 5, &redis_conn)
  config.average_scheduled_poll_interval = 1 # poll every second
end

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: threads_count.to_i + 2, &redis_conn)
end
