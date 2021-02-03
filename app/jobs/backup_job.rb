# frozen_string_literal: true

class BackupJob
  include Sidekiq::Worker
  sidekiq_options queue: 'cron'

  def perform
    config = Rails.configuration.database_configuration[Rails.env]
    s3 = S3BackupService.new
    filename = "patterns-#{Rails.env}-#{Time.zone.now.strftime('%Y%m%dT%H%M')}.sql"
    path = '/tmp/'
    filepath = path + filename
    system("mysqldump -u #{config['username']} -h #{config['host']} -p#{config['password']} #{config['database']} > gzip -9 #{path}#{filename}.gz")
    s3.upload(filepath+'.gz')
  end
end
