# frozen_string_literal: true

desc 'back up the db to S3'
task :backup do
  config = Rails.configuration.database_configuration[Rails.env]
  s3 = S3BackupService.new
  filename = "patterns-#{Rails.env}-#{Time.zone.now.strftime('%Y%m%dT%H%M')}.sql"
  path = '/tmp/'
  filepath = path + filename
  system("mysqldump -u #{config['username']} -h #{config['host']} -p#{config['password']} #{config['database']} > #{path}#{filename}")
  s3.upload(filepath)
end

task :download_latest_backup do
  privkey = gets 'Path to private key:'
  return if privkey.blank?

  filename = gets 'Filename, or blank to get latest backup'
  filename = filename.presence || 'latest'
  s3 = S3BackupService.new
  s3.download(filename, privkey, '.')
end
