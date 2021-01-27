# frozen_string_literal: true

class RapidproUpdateJob
  include Sidekiq::Worker
  sidekiq_options retry: 5
  sidekiq_options queue: 'rapidpro'

  # works like so, if person has no rapidpro uuid, we post with phone,
  # otherwise use uuid. this will allow changes to phone numbers.
  # additionally, it means we only need one worker.
  def perform(id)
    @headers = { 'Authorization' => "Token #{Rails.application.credentials.rapidpro[:token]}", 'Content-Type' => 'application/json' }
    @base_url = "https://#{Rails.application.credentials.rapidpro[:domain]}/api/v2/"

    Sidekiq.logger.info "[RapidProUpdate] job started: #{id}"

    @person = Person.find(id)
    @redis = Redis.current

    # TODO: (EL) should we early-return?
    if @person.tag_list.include?('not dig') || @person.active == false
      Sidekiq.logger.info "[RapidProUpdate] job exit not dig or not active: #{id}"
      RapidproDeleteJob.perform_async(id)
      return true
    end

    # we may deal with a word where rapidpro does email...
    # but not now.
    if @person.phone_number.present? && Phony.plausible?(@person.phone_number)
      endpoint_url = "#{@base_url}contacts.json"

      body = { name: @person.full_name,
               first_name: @person.first_name,
               language: RapidproService.language_for_person(@person) }

      # eventual fields: # first_name: person.first_name,
      # last_name: person.last_name,
      # email_address: person.email_address,
      # zip_code: person.postal_code,
      # neighborhood: person.neighborhood,
      # patterns_token: person.token,
      # patterns_id: person.id

      urn = "tel:#{@person.phone_number}"

      if @person&.rapidpro_uuid.present? # already created in rapidpro
        Sidekiq.logger.info("[RapidProUpdate] person alredy synced, sending update now: #{@person.id}")
        groups = ['DIG'] + @person.carts.where(rapidpro_sync: true).where.not(rapidpro_uuid: nil).map(&:name)
        groups.compact!
        url = endpoint_url + "?uuid=#{@person.rapidpro_uuid}"
        body[:urns] = [urn] # adds new phone number if need be.
        body[:urns] << "mailto:#{@person.email_address}" if @person.email_address.present?
        body[:groups] = groups
        body[:name] = @person.full_name
        # rapidpro tags are space delimited and have underscores for spaces
        body[:fields] = { tags: @person.tag_list.map { |t| t.tr(' ', '_') }.join(' '),
                          verified: @person.verified }

      else # person doesn't yet exist in rapidpro
        # TODO: (EL) should we also set urns, groups, and fields?
        # (BC) Can't set urns groups and fields.
        # Have to make two requests. One to create the person
        # and then another to set fields
        cgi_urn = CGI.escape(urn)
        url = endpoint_url + "?urn=#{cgi_urn}" # uses phone number to identify.
        Sidekiq.logger.info("[RapidProUpdate] person not in rapidpro, sending another update later: #{@person.id}")
        # update groups, fields, etc
        RapidproUpdateJob.perform_in(rand(120..240), @person.id)
      end

      Sidekiq.logger.info("[RapidProUpdate] sending the request: #{@person.id}")

      begin
        Sidekiq.logger.info("[RapidProUpdate] in begin;rescue;end: #{@person.id}")

        # body_sha1 = Digest::SHA1.hexdigest body.to_json
        # if @redis.get("rapidpro_update_throttle:#{@person.id}:#{body_sha1}").present? && Rails.env.production? # less hammering of rapidpro
        #   Sidekiq.logger.info("[RapidProUpdate] throttled: #{@person.id}")
        #   return true
        # end
        #Sidekiq.logger.info("[RapidProUpdate] not throttled, making request: #{@person.id}")

        res = HTTParty.post(url, headers: @headers, body: body.to_json, timeout: 10)

        Sidekiq.logger.info("[RapidProUpdate] request sent: #{@person.id} http: #{res.code}")
      rescue Net::ReadTimeout => e
        Sidekiq.logger.info("[RapidProUpdate] timeout. id: #{id}, error: #{e}")
        RapidproUpdateJob.perform_in(rand(120..2400), id)
        return true
      end

      Sidekiq.logger.info("rapidpro job: #{@person.id}::#{res.code} #{res.parsed_response}")
      case res.code
      when 201 # new person in rapidpro
        Sidekiq.logger.info("[RapidProUpdate] added person to rapidpro: #{@person.id}")
        # store the sha1 of the body
        # @redis.setex("rapidpro_update_throttle:#{@person.id}:#{body_sha1}", 1.day.to_i, true) if Rails.env.production?
        if @person.rapidpro_uuid.blank?
          @person.rapidpro_uuid = res.parsed_response['uuid']
          @person.save # this calls the rapidpro update again, for the other attributes
        end
        true
      when 429 # throttled
        Sidekiq.logger.info("[RapidProUpdate] throttled. id: #{id}, Retry-after: #{res.headers['retry-after']}")
        retry_delay = res.headers['retry-after'].to_i + 5
        RapidproUpdateJob.perform_in(retry_delay, id) # re-queue job
      when 200 # happy response
        @redis.setex("rapidpro_update_throttle:#{@person.id}:#{body_sha1}", 1.day.to_i, true) if Rails.env.production?
        Sidekiq.logger.info("[RapidProUpdate] success for id: #{id}")
        if res.parsed_response.present? && @person.rapidpro_uuid.blank?
          Sidekiq.logger.info("[RapidProUpdate] saving uuid: #{id}")
          @person.rapidpro_uuid = res.parsed_response['uuid']
          @person.save # this calls the rapidpro update again, for the other attributes
        end
        true
      when 400, 502, 504, 500
        Sidekiq.logger.info("[RapidProUpdate] Other Error. id: #{id}, #{res.code}, #{res.parsed_response}")
        # re-queue job for a random time in the future. thundering herd.
        RapidproUpdateJob.perform_in(rand(120..2400), id)
        true
      else
        Sidekiq.logger.info("[RapidProUpdate] unknown http error for id: #{id}, #{res.code}, #{res.body}")
        raise "error: #{res.code}, #{res.body}"
      end
    else
      Sidekiq.logger.info("[RapidProUpdate] sending delete job for id: #{id}")
      RapidproDeleteJob.perform_async(id)
    end
  end
end
