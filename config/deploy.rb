# frozen_string_literal: true

require 'bundler/capistrano'
require 'capistrano'
require 'capistrano/sidekiq'
require 'capistrano/ext/multistage'
set :whenever_command, 'bundle exec whenever'
require 'whenever/capistrano'
require 'rvm/capistrano'
require 'rvm/capistrano/gem_install_uninstall'
require 'dotenv/load'

set :repository, ENV['GIT_REPOSITORY']

set :scm, :git
set(:deploy_to) { "/var/www/#{application}" }
set :deploy_via, :remote_cache
set :use_sudo, false
set :user, 'patterns'
set :keep_releases, 10
set :stages, %w[production staging]
set :default_stage, 'staging'

set :sidekiq_config, 'config/sidekiq.yml'
set :sidekiq_processes, 2

set :bundle_flags, '--deployment --quiet'

# more info: rvm help autolibs
set :rvm_autolibs_flag, 'read-only'

# install/update RVM
before 'deploy', 'rvm:install_rvm'

ENV['GEM'] = 'bundler'
# Make sure Bundler is installed for gemset
before 'bundle:install', 'rvm:install_gem'

# install Ruby and create gemset (both if missing)
before 'deploy', 'rvm:install_ruby'

set :ssh_options, forward_agent: true
# set :shared_children, fetch(:shared_children) + ["sharedconfig"]

before  'deploy:finalize_update', 'deploy:create_shared_directories', 'deploy:link_db_config', 'deploy:link_env_var'
# before  'deploy:finalize_update', 'deploy:link_db_config', 'deploy:link_env_var'

after   'deploy:finalize_update', 'deploy:create_binstubs', 'deploy:migrate', 'deploy:reload_nginx', 'deploy:cleanup'

namespace :deploy do
  task :start do
    run "cd #{current_path} && `bundle exec unicorn_rails -c config/unicorn.rb -E #{rails_env.to_s.shellescape} -D`"
  end

  task :stop do
    run "cd #{current_path} && kill -TERM `cat tmp/pids/unicorn.pid`"
  end

  task :restart do
    # unicorn reloads on USR2
    run "cd #{current_path} && kill -USR2 `cat tmp/pids/unicorn.pid`"
  end

  task :create_shared_directories do
    run "mkdir -p #{deploy_to}/shared/pids"
    run "mkdir -p #{deploy_to}/shared/system"
    run "mkdir -p #{deploy_to}/shared/assets"
    run "mkdir -p #{deploy_to}/releases"
    run "mkdir -p #{shared_path}/log"
    run "mkdir -p #{shared_path}/tmp"
    run "mkdir -p #{shared_path}/assets"
    run "mkdir -p #{shared_path}/bundle"
    run "mkdir -p #{shared_path}/cached-copy"
  end

  task :link_db_config do
    # pull in database.yml on server
    run "rm -f #{release_path}/config/database.yml && ln -s #{deploy_to}/shared/database.yml #{release_path}/config/database.yml"
  end

  # https://github.com/capistrano/capistrano/issues/362#issuecomment-14158487
  namespace :assets do
    task :precompile, roles: assets_role, except: { no_release: true } do
      run <<-CMD.compact
        cd -- #{latest_release.shellescape} &&
        #{rake} RAILS_ENV=#{rails_env.to_s.shellescape} #{asset_env} assets:precompile
      CMD
    end
  end

  # rewrite binstubs
  task :create_binstubs do
    run "cd #{latest_release.shellescape} && bundle binstubs unicorn --force --path ./bin"
  end
end
