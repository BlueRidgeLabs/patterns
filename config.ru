# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path("../config/environment", __FILE__)
run Patterns::Application

# no more delayed job web
# if Rails.env.production?
#   DelayedJobWeb.use Rack::Auth::Basic do |username, password|
#     ActiveSupport::SecurityUtils.variable_size_secure_compare('admin', username) &&
#       ActiveSupport::SecurityUtils.variable_size_secure_compare(ENV['DJ_PASSWORD'], password)
#   end
# end
