# frozen_string_literal: true

source 'https://rubygems.org'
ruby '~> 2.7.0'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'airbrake'
gem 'bootsnap', require: false
gem 'rack'
gem 'rack-cache'
gem 'rails', '~> 6.0.0'

# gem 'webpacker', '~> 4.x' #bundle exec rails webpacker:install:stimulus #sooon

gem 'rails-i18n'
# gem 'pg' # soooooon!
gem 'mysql2'

gem 'active_record_doctor', group: :development
gem 'hiredis' # faster redis
gem 'mail'
gem 'redis' # ephemeral storage and caching
gem 'redis-rails' # for session store, I think deprecated in rails 5.2
gem 'validates_overlap' # to ensure we don't double book people

gem 'ransack' # rad searching.

gem 'mandrill-rails' # for inbound email

gem 'awesome_print' # for printing awesomely

gem 'fuzzy_match' # for sms command fuzzy matching

gem 'chartkick'
gem 'groupdate' # for graphing
gem 'nokogiri'

# csv files are TERRIBLE for importing. Excel messes with column formats
gem 'axlsx', '~> 3.0.0.pre'
gem 'roo'
gem 'rubyzip'

gem 'redcarpet' # for markdown notes

# giftrocket API for automagic giftcarding
gem 'tremendous_ruby', github: 'talkable/tremendous-ruby', branch: 'rails-6.0'

gem 'aws-sdk-s3'
gem 'image_processing' # for activestorage image processing

gem 'hashie'

group :production do
  # gem 'newrelic_rpm'
  gem 'lograge' # sane logs
  # gem 'skylight' # perf

  gem 'unicorn', '5.4.1' # Use unicorn as the app server
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails'
  gem 'sassc-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'mini_racer'
  gem 'uglifier'
end

gem 'jquery-rails'
gem 'jquery-turbolinks'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

# To use ActiveModel has_secure_password
gem 'bcrypt'

# bootstrapping
gem 'bootstrap', '~> 4.4.0'
gem 'bootstrap4-datetime-picker-rails'
gem 'font-awesome-rails', '~> 4.7', '>= 4.7.0.1'
gem 'glyphicons-rails'
gem 'momentjs-rails' # sane time management in js

# want to switch pagination to kaminari
# http://blogs.element-labs.com/2015/10/replacing-will_paginate-with-kaminari/

# pagniate with will_paginate: https://github.com/mislav/will_paginate
gem 'will_paginate'
gem 'will_paginate-bootstrap4'

# include health_check, for system monitoring
gem 'health_check'

# use devise for auth/identity
gem 'devise'
gem 'devise_invitable'
gem 'devise_token_auth'
gem 'devise_zxcvbn' # password strength filter

# use gibbon for easy Mailchimp API access
gem 'gibbon'

# use twilio-ruby for twilio
gem 'twilio-ruby'

gem 'parallel' # for parallel processing.

gem 'httparty'
# use Wuparty for wufoo
# gem 'wuparty' # breaks latest version of httparty

# Use gsm_encoder to help text messages send correctly
gem 'gsm_encoder'

# not sidekiq 6 yet. need to upgrade capistrano first
gem 'sidekiq', '~> 5.2.0'
gem 'sidekiq-scheduler'

# phone number validation
gem 'phony_rails'

# zip code validation
gem 'validates_zipcode'

# in place editing
gem 'best_in_place', '~> 3.0.1'

# validation for new persons on the public page.
gem 'jquery-validation-rails'

# to validate gift card numbers
gem 'credit_card_validations'

# for automatically populating tags
gem 'twitter-typeahead-rails'

# make ical events and feeds
gem 'icalendar'

# state machine for reservations.
gem 'aasm'
gem 'after_commit_everywhere', '~> 0.1', '>= 0.1.5'

# using sidekiq scheduluer, and direct to s3
# # cron jobs for backups and sending reminders
# gem 'backup', require: false
# gem 'whenever', require: false

# handling emoji!
gem 'emoji'

# auditing.
gem 'paper_trail'
gem 'paper_trail-association_tracking'
gem 'paper_trail-globalid'

# webrick is slow, capybara will use puma instead
gem 'puma'

# gem "faster_path" # will break without rustc
gem 'fast_blank'

# storing money with money-rails
gem 'money-rails'

# masked inputs
gem 'jquery_mask_rails'

# the standard rails tagging library
gem 'acts-as-taggable-on'

# mapping, because maps rock and google sucks
gem 'leaflet-rails'

group :development do
  # gem 'capistrano'
  # mainline cap is busted w/r/t Rails 4. Try this fork instead.
  # src: https://github.com/capistrano/capistrano/pull/412
  gem 'capistrano', '~> 2.15.4', require: false
  gem 'capistrano-sidekiq', require: false
  gem 'ed25519'
  gem 'heavens_door' # recording capybara tests
  gem 'lol_dba' # find columns that should have indices
  gem 'rbnacl', require: false
  gem 'rvm-capistrano', require: false
  # gem 'rbnacl-libsodium' # same as above
  gem 'bcrypt_pbkdf' # same as above
  # this whole group makes finding performance issues much friendlier
  gem 'bundler-audit', '>= 0.5.0', require: false
  gem 'derailed_benchmarks'

  # gem 'flamegraph'
  # gem 'memory_profiler'
  # gem "rack-mini-profiler"
  # gem 'ruby-prof'
  # gem 'stackprof' # ruby 2.1+ only
  # n+1 killer.
  # gem 'bullet'

  # what attributes does this model actually have?
  gem 'annotate', require: false

  # a console in your tests, to find out what's actually happening
  gem 'pry-rails'

  # a console in your browser, when you want to interrogate views.
  gem 'web-console'

  gem 'rails-erd', require: false
  # silences logging of requests for assets
  # gem 'quiet_assets'

  # enabling us to deploy via travis and encrypted keys!
  # gem 'travis'
  # gem 'spring' is this even a thing anymore?
  gem 'foreman', require: false # for procfile
  gem 'guard', require: false
  gem 'guard-bundler', require: false
  gem 'guard-minitest', require: false
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', require: false

  gem 'rubocop', '~> 0.80', require: false
end

group :test do
  # mock tests w/mocha
  gem 'mocha', require: false
  gem 'sqlite3', platform: %i[ruby mswin mingw]
  ## for JRuby
  # gem 'jdbc-sqlite3', platform: :jruby
  gem 'coveralls', require: false
  gem 'memory_test_fix' # in memory DB, for the speedy
  # generate fake data w/faker: http://rubydoc.info/github/stympy/faker/master/frames

  gem 'simplecov', '0.16', require: false
  # screenshots when capybara fails
  gem 'capybara-screenshot'
  # retry poltergeist specs. they are finicky
  gem 'rspec-retry'
  # calendaring tests will almost always break on saturdays.
  gem 'timecop'

  gem 'webmock'
  # in memory redis for testing only
  # gem 'mock_redis'
  gem 'capybara'
  gem 'capybara-email'
  gem 'database_cleaner'
  gem 'parallel_tests' # https://devopsvoyage.com/2018/10/22/execute-rspec-locally-in-parallel.html
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rspec-sidekiq'
  gem 'selenium-webdriver'
  gem 'shoulda'
  gem 'sms-spec'
  gem 'vcr'
  gem 'webdrivers'
end

group :development, :test do
  # use holder for placeholder images
  gem 'apparition'
  gem 'byebug', '~> 11.0'
  gem 'concurrent-ruby'
  gem 'dotenv-rails'
  gem 'factory_bot_rails', '4.10.0', require: false
  gem 'faker', require: false
  gem 'holder_rails'
  gem 'pry' # a console anywhere!
  # gem 'rubocop-faker', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rails_config', require: false
  gem 'rubocop-rspec', require: false

  # To use debugger
  # gem 'debugger'
end
