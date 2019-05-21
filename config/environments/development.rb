Patterns::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Bullet.enable = true
  # Bullet.bullet_logger = true
  # base url for emails
  config.action_mailer.default_url_options = { host: 'localhost:8080' }

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false
  ips = %w(192.168.0.0/16 172.0.0.0/8)
  ips.append *ENV['WEBCONSOLE_IPS'].split(',') if ENV['WEBCONSOLE_IPS'].present?
  config.web_console.whitelisted_ips = ips

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_dispatch.default_headers = {
    'Access-Control-Allow-Origin' => '*',
    'Access-Control-Request-Method' => %w{GET POST OPTIONS}.join(",")
  }

  config.sass.inline_source_maps = true
  
  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log
  config.log_formatter = ::Logger::Formatter.new

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  config.assets.debug = true
  config.assets.quiet = true

  config.middleware.use Rack::TwilioWebhookAuthentication, ENV['TWILIO_AUTH_TOKEN'], '/receive_text/index'

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = false

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  config.active_storage.service = :local
  
  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end
