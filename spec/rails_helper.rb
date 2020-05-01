# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
if Rails.env.production?
  abort('The Rails environment is running in production mode!')
end
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!

require 'shoulda/matchers'
require 'database_cleaner'
require 'support/helpers'
require 'sms_spec'
require 'timecop'
require 'mock_redis'
require 'simplecov'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'webmock'
# require 'best_in_place/test_helpers' #busted

SimpleCov.start
SmsSpec.driver = :'twilio-ruby'

# mocking out redis for our tests
Redis.current = MockRedis.new

# keeps out sql output hidden
ActiveRecord::Base.logger = nil

require 'devise'
require 'support/controller_macros'
require 'action_mailbox/test_helper'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Capybara.configure do |config|
#   config.server_port = 9887 + ENV['TEST_ENV_NUMBER'].to_i
# end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # config.include Helpers
  config.extend ControllerMacros, type: :controller
  config.include Helpers

  config.include ActionMailbox::TestHelper, type: :mailbox
  # config.include BestInPlace::TestHelpers #busted

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.profile_examples = true

  config.include Devise::Test::ControllerHelpers, type: :controller
end
