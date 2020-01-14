# frozen_string_literal: true

desc "back up the db to S3"
task :backup do
  sh "backup perform --trigger my_backup -r /var/www/patterns-production/current/"
end
