# frozen_string_literal: true

set :application, 'patterns-staging'
set :branch, fetch(:branch, ENV['STAGING_BRANCH'])
set :user, 'patterns'
set :rails_env, :staging
set :rvm_ruby_string, '2.6.2@staging' # use the same ruby as used locally for deployment

server ENV['STAGING_SERVER'], :app, :web, :db, primary: true

task :link_env_var do
  # pull in database.yml on server
  #run "rm -f #{release_path}/config/local_env.yml && ln -s #{deploy_to}/shared/local_env.yml #{release_path}/config/local_env.yml"
end
