# frozen_string_literal: true

class DailyUserRemindersJob
  include Sidekiq::Worker
  sidekiq_options queue: 'cron'

  def perform
    User.send_all_reminders
  end
end
