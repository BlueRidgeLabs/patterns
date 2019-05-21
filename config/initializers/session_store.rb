# Be sure to restart your server when you modify this file.

Patterns::Application.config.session_store :redis_store,
  servers: [ENV['REDIS_URL'] || "redis://localhost:6379/0/session"],
  secure: (Rails.env.production? || Rails.env.staging?)
