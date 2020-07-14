# frozen_string_literal: true

class RapidproDeleteJob
  include Sidekiq::Worker
  sidekiq_options retry: 5
  sidekiq_options queue: 'rapidpro'

  def perform(id)
    Rails.logger.info '[RapidProDelete] job enqueued'
    person = Person.unscoped.find id
    if person.rapidpro_uuid.present?
      headers = { 'Authorization' => "Token #{ENV['RAPIDPRO_TOKEN']}",
                  'Content-Type' => 'application/json' }
      url = "https://rapidpro.brl.nyc/api/v2/contacts.json?uuid=#{person.rapidpro_uuid}"
      res = HTTParty.delete(url, headers: headers)

      case res.code
      when 404
        false
      when 204, 201, 200 # successful delete
        person.rapidpro_uuid = nil
        person.save
        true
      when 429 # rapidpro rate limiting us.
        retry_delay = res.headers['retry-after'].to_i + 5
        RapidproDeleteJob.perform_in(retry_delay, id)
      else
        raise 'RapidPro Web request Error. Is Rapidpro Up?'
      end
    end
  end
end
