# frozen_string_literal: true

# Backup v5.x Configuration
##
# Backup Generated: my_backup
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t my_backup [-c <path_to_configuration_file>]
#
# For more information about Backup's components, see the documentation at:
# http://backup.github.io/backup
#
require 'cgi'
require 'uri'

Model.new(:hourly_backup) do
  database MySQL do |db|
    db_params = get_db_params
    # To dump all databases, set `db.name = :all` (or leave blank)
    db.name               = db_params[:database]
    db.username           = db_params[:username]
    db.password           = db_params[:password]
    db.host               = db_params[:host]
    db.port               = db_params[:port]
    # Note: when using `skip_tables` with the `db.name = :all` option,
    # table names should be prefixed with a database name.
    # e.g. ["db_name.table_to_skip", ...]
    # db.skip_tables        = ["skip", "these", "tables"]
    # db.only_tables        = ["only", "these", "tables"]
    db.additional_options = ['--quick', '--single-transaction']
  end

  # no local storage anymore. 12 factor!
  # store_with Local do |local|
  #   storage_id = :hourly
  #   local.keep = 48
  #   local.path = "/var/www/patterns-production/shared/backups/#{storage_id}"
  # end

  ##
  # Gzip [Compressor]
  #
  compress_with Gzip

  encrypt_with GPG do |encryption|
    encryption.keys = {}
    encryption.keys[Rails.application.credentials.mailer[:admin]] = File.read('/home/patterns/backup_public_key.pub')
    encryption.recipients = Rails.application.credentials.mailer[:admin]
  end
end

Model.new(:daily_backup, 'the daily backup') do
  ##
  # Archive [Archive]
  #
  # Adding a file or directory (including sub-directories):
  #   archive.add "/path/to/a/file.rb"
  #   archive.add "/path/to/a/directory/"
  #
  # Excluding a file or directory (including sub-directories):
  #   archive.exclude "/path/to/an/excluded_file.rb"
  #   archive.exclude "/path/to/an/excluded_directory
  #
  # By default, relative paths will be relative to the directory
  # where `backup perform` is executed, and they will be expanded
  # to the root of the filesystem when added to the archive.
  #
  # If a `root` path is set, relative paths will be relative to the
  # given `root` path and will not be expanded when added to the archive.
  #
  #   archive.root '/path/to/archive/root'
  #
  # archive :my_archive do |archive|
  #   # Run the `tar` command using `sudo`
  #   # archive.use_sudo
  #   archive.add "/path/to/a/file.rb"
  #   archive.add "/path/to/a/folder/"
  #   archive.exclude "/path/to/a/excluded_file.rb"
  #   archive.exclude "/path/to/a/excluded_folder"
  # end

  ##
  # MySQL [Database]
  #
  database MySQL do |db|
    db_params = get_db_params
    # To dump all databases, set `db.name = :all` (or leave blank)
    db.name               = db_params[:database]
    db.username           = db_params[:username]
    db.password           = db_params[:password]
    db.host               = db_params[:host]
    db.port               = db_params[:port]
    # Note: when using `skip_tables` with the `db.name = :all` option,
    # table names should be prefixed with a database name.
    # e.g. ["db_name.table_to_skip", ...]
    # db.skip_tables        = ["skip", "these", "tables"]
    # db.only_tables        = ["only", "these", "tables"]
    db.additional_options = ['--quick', '--single-transaction']
  end

  ##
  # Amazon Simple Storage Service [Storage]
  #
  store_with S3 do |s3|
    # AWS Credentials
    s3.access_key_id     = Rails.application.credentials.aws[:api_token]
    s3.secret_access_key = Rails.application.credentials.aws[:api_secret]
    # Or, to use a IAM Profile:
    # s3.use_iam_profile = true

    s3.region            = 'us-east-1'
    s3.bucket            = Rails.application.credentials.aws[:s3_bucket]
    s3.path              = "/patterns_backups_#{ENV['RAILS_ENV']}"
    s3.keep              = 200
    # s3.keep              = Time.now - 2592000 # Remove all backups older than 1 month.
  end

  ##
  # Local (Copy) [Storage]
  #

  # no local storage anymore. 12 factor!
  # store_with Local do |local|
  #   time = Time.now
  #   if time.day == 1 # first day of the monthf
  #     storage_id = :monthly
  #     keep = 12
  #   elsif time.sunday?
  #     storage_id = :weekly
  #     keep = 4
  #   else
  #     storage_id = :daily
  #     keep = 7
  #   end
  #   local.path  = "/var/www/patterns-production/shared/backups/#{storage_id}"
  #   local.keep  = keep
  # end

  ##
  # Gzip [Compressor]
  #
  compress_with Gzip

  encrypt_with GPG do |encryption|
    encryption.keys = {}
    pubkey = Rails.application.credentials.backup_public_key
    encryption.keys[Rails.application.credentials.mailer[:admin]] = pubkey
    encryption.recipients = Rails.application.credentials.mailer[:admin]
  end
  ##
  # Mail [Notifier]
  #
  # The default delivery method for Mail Notifiers is 'SMTP'.
  # See the documentation for other delivery options.
  #
  notify_by Mail do |mail|
    mail.on_success           = false
    mail.on_warning           = false
    mail.on_failure           = true

    mail.from                 = Rails.application.credentials.mailer[:sender]
    mail.to                   = Rails.application.credentials.mailer[:admin]
    mail.address              = Rails.application.credentials.smtp[:host]
    mail.port                 = Rails.application.credentials.smtp[:port]
    mail.domain               = ENV["#{ENV['RAILS_ENV'].upcase}_SERVER"]
    mail.user_name            = Rails.application.credentials.smtp[:username]
    mail.password             = Rails.application.credentials.smtp[:username]
    mail.authentication       = 'plain'
    mail.encryption           = :starttls
  end
end

def get_db_params # rubocop:todo Naming/AccessorMethodName
  uri = URI.parse(ENV['DATABASE_URL'])
  database = "#{(uri.path || '').split('/')[1]}_#{env}"
  adapter = case uri.scheme.to_s
            when 'postgres' then 'postgresql'
            when 'mysql'    then 'mysql2'
            else uri.scheme.to_s
            end
  { username: uri.user,
    password: uri.password,
    host: uri.host,
    port: uri.port,
    database: database,
    adapter: adapter }
end
