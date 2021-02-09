# config valid for current version and patch releases of Capistrano

lock '~> 3.15.0'
require 'dotenv'
Dotenv.load

set :application, 'patterns'
set :repo_url, 'git@github.com:BlueRidgeLabs/patterns.git'

set :user, 'patterns'

append :linked_dirs

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for default_env is {}
#set :default_env, { path: "#{shared_path.join('bin')}:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system', 'public/uploads'
append :linked_files, 'config/secrets.yml'

set :rvm_type, :system # Defaults to: :auto
set :rvm_ruby_version, '2.7.2' # Defaults to: 'default'

# bundler defaults

set :ssh_options, forward_agent: true

# rails
set :conditionally_migrate, true
set :migration_role, :app

set :sidekiq_processes, 2
set :sidekiq_user, 'patterns'

# puma
set :puma_init_active_record, true



on roles :all do
  within fetch(:latest_release_directory) do
    with rails_env: fetch(:rails_env) do
      execute :rake, 'assets:precompile'
    end
  end
end
