# frozen_string_literal: true

require File.expand_path('boot', __dir__)
require_relative 'boot'
require 'rails/all'

# Assets should be precompiled for production (so we don't need the gems loaded then)
Bundler.setup
Bundler.require(*Rails.groups)

module Patterns
  class Application < Rails::Application
    # this enables us to know who created a user or updated a user
    require "#{config.root}/lib/extensions/with_user"

    config.load_defaults 6.0
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    config.autoload_paths += %W[#{config.root}/app/jobs #{config.root}/app/mailers #{config.root}/app/services #{config.root}/app/sms]

    # Analytics
    Patterns::Application.config.google_analytics_enabled = false

    # compile the placeholder
    config.assets.precompile += %w[holder.js]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = ENV['TIME_ZONE'] || 'Central Time (US & Canada)'

    # Do not swallow errors in after_commit/after_rollback callbacks.
    # config.active_record.raise_in_transactional_callbacks = true
    config.active_record.cache_versioning = false
    config.action_cable.mount_path = '/cable'
    redis_str = ENV['REDIS_URL'] || 'redis://localhost:6379/0/cache'
    config.cache_store = :redis_store, redis_str, { expires_in: 90.minutes }

    config.active_job.queue_adapter = :sidekiq

    config.generators do |g|
      g.test_framework :rspec
      g.jbuilder false
      g.assets false
      g.helper false
    end
  end
end
