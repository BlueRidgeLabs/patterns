# config valid for current version and patch releases of Capistrano
lock "~> 3.15.0"

set :application, "patterns"
set :repo_url, "git@github.com:BlueRidgeLabs/patterns.git"

set :user, 'patterns'

append :linked_dirs

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :rvm_type, :user                     # Defaults to: :auto
set :rvm_ruby_version, '2.7,2'      # Defaults to: 'default'

set :sidekiq_processes, 2
set :sidekiq_user, 'patterns'
set :bundle_flags, '--quiet -j 4'

set :ssh_options, forward_agent: false

# rails
set :conditionally_migrate, true
set :migration_role, :app

# puma
set :puma_init_active_record, true

append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system', 'public/uploads'
append :linked_files, 'config/database.yml', 'config/secrets.yml'

on roles :all do
  within fetch(:latest_release_directory) do
    with rails_env: fetch(:rails_env) do
      execute :rake, 'assets:precompile'
    end
  end
end
