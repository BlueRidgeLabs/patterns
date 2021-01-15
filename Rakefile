# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('config/application', __dir__)

Patterns::Application.load_tasks

if !Rails.env.production? && !Rails.env.staging?
  require 'coveralls/rake/task'
  Coveralls::RakeTask.new
  task test_with_coveralls: [:spec, :features, 'coveralls:push']

  task default: [:spec, 'coveralls:push']
end

desc 'Send reminders'
task send_reminders: :environment do # :environment will load our Rails app, so we can query the database with ActiveRecord
  User.send_all_reminders
end

desc 'update participation levels'
task update_participation_levels: :environment do # :environment will load our Rails app, so we can query the database with ActiveRecord
  Person.update_all_participation_levels
end
