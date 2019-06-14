source 'https://rubygems.org'
ruby '2.6.2'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.2.3'
gem 'rails-i18n'
gem 'actioncable'
gem 'bootsnap', require: false
gem 'rack-cache'
gem 'airbrake', '~> 5.0' # sends errors to external service
# gem 'pg' # soooooon!
gem 'mysql2'

gem 'hiredis' # faster redis
gem 'redis' # ephemeral storage and caching
gem 'redis-rails' # for session store, I think deprecated in rails 5.2
gem 'validates_overlap' # to ensure we don't double book people

#gem 'rails_12factor' # don't need this. yet. soon!

gem 'mail'

gem 'ransack' # rad searching.

gem 'mandrill-rails' # for inbound email

gem 'awesome_print' # for printing awesomely

gem 'fuzzy_match' # for sms command fuzzy matching

gem 'groupdate' # for graphing
gem 'chartkick'
gem 'nokogiri'

# csv files are TERRIBLE for importing. Excel messes with column formats
gem 'axlsx', '~> 3.0.0.pre'
gem 'rubyzip'
gem 'roo'

gem 'redcarpet' # for markdown notes

#giftrocket API for automagic giftcarding
gem 'giftrocket_ruby', github: 'BlueRidgeLabs/giftrocket-ruby'

gem "aws-sdk-s3", require: false

gem "hashie"

# generate capybara tests


group :development do
  # gem 'capistrano'
  # mainline cap is busted w/r/t Rails 4. Try this fork instead.
  # src: https://github.com/capistrano/capistrano/pull/412
  gem 'lol_dba' # find columns that should have indices
  gem 'heavens_door' # recording capybara tests
  gem 'capistrano', '~> 2.15.4'
  gem 'capistrano-sidekiq'
  gem 'ed25519'
  gem 'rvm-capistrano', require: false
  gem 'rbnacl', '~> 4.0.0' # for modern ssh keys
  #gem 'rbnacl-libsodium' # same as above
  gem 'bcrypt_pbkdf' # same as above
  # this whole group makes finding performance issues much friendlier
  gem 'flamegraph'
  gem 'memory_profiler'
  gem 'rack-mini-profiler'
  gem 'ruby-prof'
  gem 'stackprof' # ruby 2.1+ only
  gem "bundler-audit", ">= 0.5.0", require: false
  # n+1 killer.
  # gem 'bullet'

  # what attributes does this model actually have?
  gem 'annotate'

  # a console in your tests, to find out what's actually happening
  gem 'pry-rails'

  # a console in your browser, when you want to interrogate views.
  gem 'web-console'

  gem 'rails-erd'
  # silences logging of requests for assets
  #gem 'quiet_assets'

  # enabling us to deploy via travis and encrypted keys!
  #gem 'travis'
end

group :production do
  #gem 'newrelic_rpm'
  gem 'skylight' # perf
  gem 'lograge' # sane logs

  gem 'unicorn', "5.4.1" # Use unicorn as the app server
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails'
  gem 'sassc-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', platforms: :ruby
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

# To use debugger
# gem 'debugger'

# https://coderwall.com/p/fnfdgw/useful-regular-expressions-to-update-to-bootstrap-3
gem 'twitter-bootstrap-rails', '~> 2.2.0'
gem 'glyphicons-rails'
gem 'momentjs-rails' # sane time management in js
gem 'bootstrap3-datetimepicker-rails'

# want to switch pagination to kaminari
# http://blogs.element-labs.com/2015/10/replacing-will_paginate-with-kaminari/

# pagniate with will_paginate: https://github.com/mislav/will_paginate
gem 'will_paginate'
gem 'will_paginate-bootstrap', '~> 0.2.5' # Bootstrap 2 support breaks at v1.0

# include health_check, for system monitoring
gem 'health_check'

# use devise for auth/identity
gem 'devise'
gem 'devise_invitable'
gem 'devise_zxcvbn' # password strength filter

# use gibbon for easy Mailchimp API access
gem 'gibbon'

# use twilio-ruby for twilio
gem 'twilio-ruby'

gem 'parallel' # for parallel processing.

gem 'httparty'
# use Wuparty for wufoo
#gem 'wuparty' # breaks latest version of httparty

# Use gsm_encoder to help text messages send correctly
gem 'gsm_encoder'

# Switching to sidekiq: async, threaded, less memory,
# more performance. Important for responsiveness
# for background tasks users are waiting for.
gem 'sidekiq'

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

# cron jobs for backups and sending reminders
gem 'whenever', require: false
#gem 'backup', require: false

# handling emoji!
gem 'emoji'

# auditing.
gem 'paper_trail'
gem 'paper_trail-globalid'
gem 'paper_trail-association_tracking'

gem 'fast_blank' # blank? rewritten in c

#gem 'faster_path' #if !`which rustc`.empty?

# storing money with money-rails
gem 'money-rails'

# masked inputs
gem 'jquery_mask_rails'

# the standard rails tagging library
gem 'acts-as-taggable-on'

# mapping, because maps rock and google sucks
gem 'leaflet-rails'

group :test do
  # mock tests w/mocha
  gem 'mocha', require: false
  gem 'sqlite3', platform: %i[ruby mswin mingw]
  ## for JRuby
  # gem 'jdbc-sqlite3', platform: :jruby
  gem 'memory_test_fix' # in memory DB, for the speedy
  gem 'coveralls', require: false
  # generate fake data w/faker: http://rubydoc.info/github/stympy/faker/master/frames
  gem 'faker'
  gem 'simplecov', require: false
  # screenshots when capybara fails
  gem 'capybara-screenshot'
  # retry poltergeist specs. they are finicky
  gem 'rspec-retry'
  # calendaring tests will almost always break on saturdays.
  gem 'timecop'
  # webrick is slow, capybara will use puma instead
  gem 'puma'
  gem 'webmock'
  # in memory redis for testing only
  gem 'mock_redis'
  gem 'vcr'
  gem 'rspec-sidekiq'
  gem 'shoulda'
end

group :development, :test do
  # use holder for placeholder images
  gem 'parallel_tests' # https://devopsvoyage.com/2018/10/22/execute-rspec-locally-in-parallel.html
  gem 'holder_rails'
  gem 'capybara'
  gem 'apparition'
  gem "webdrivers", "~> 3.8"
  gem 'capybara-email'
  gem 'concurrent-ruby'
  gem 'database_cleaner'
  gem 'factory_bot_rails', '4.10.0', require: false
  gem 'guard'
  gem 'guard-bundler', require: false
  gem 'guard-minitest'
  gem 'guard-rspec', require: false
  gem 'rubocop', require: false
  gem "rubocop-rails_config"  
  gem 'rubocop-performance'
  gem 'guard-rubocop'
  gem 'selenium-webdriver'
  gem 'pry' # a console anywhere!
  gem 'rspec'
  gem 'rspec-rails'

  gem 'sms-spec'
  gem "byebug", "~> 11.0"
end
