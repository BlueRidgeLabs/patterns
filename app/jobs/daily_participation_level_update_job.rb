# frozen_string_literal: true

class DailyParticipationLevelUpdateJob
  include Sidekiq::Worker
  sidekiq_options queue: 'cron'

  def perform
    Person.update_all_participation_levels
  end
end
