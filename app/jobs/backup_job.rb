# frozen_string_literal: true

class BackupJob
  include Sidekiq::Worker
  sidekiq_options queue: 'cron'

  def perform(type: 'hourly')
    raise unless %w[hourly daily].include? type

    path = "/var/www/patterns-#{ENV['RAILS_ENV']}/current"

    system("cd #{path} && bundle exec backup perform --trigger #{type}_backup -r #{path}/Backup/")
  end
end
