# frozen_string_literal: true

if Rails.env != "production" && Rails.env != "staging"
  require "rubocop/rake_task"
  desc "Run rubocop"
  task :rubocop do
    RuboCop::RakeTask.new
  end
end
