# frozen_string_literal: true

class RapidproUpdateJob
  include Sidekiq::Worker
  sidekiq_options retry: 5

  # works like so, if person has no rapidpro uuid, we post with phone,
  # otherwise use uuid. this will allow changes to phone numbers.
  # additionally, it means we only need one worker.
  def perform(id)
    @headers = { "Authorization" => "Token #{ENV['RAPIDPRO_TOKEN']}", "Content-Type" => "application/json" }
    @base_url = "https://rapidpro.brl.nyc/api/v2/"
    Rails.logger.info "[RapidProUpdate] job enqueued"
    @person = Person.find(id)

    # TODO: (EL) should we early-return?
    if @person.tag_list.include?("not dig") || @person.active == false
      RapidproDeleteJob.perform_async(id)
      return
    end

    # we may deal with a word where rapidpro does email...
    # but not now.
    if @person.phone_number.present?
      endpoint_url = @base_url + "contacts.json"

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
        url = endpoint_url + "?uuid=#{@person.rapidpro_uuid}"
        body[:urns] = [urn] # adds new phone number if need be.
        if @person.email_address.present?
          body[:urns] << "mailto:#{@person.email_address}"
        end
        body[:groups] = ["DIG"]
        # rapidpro tags are space delimited and have underscores for spaces
        body[:fields] = { tags: @person.tag_list.map { |t| t.tr(" ", "_") }.join(" "),
                          verified: @person.verified }

      else # person doesn't yet exist in rapidpro
        # TODO: (EL) should we also set urns, groups, and fields?
        # (BC) Can't set urns groups and fields.
        # Have to make two requests. One to create the person
        # and then another to set fields
        cgi_urn = CGI.escape(urn)
        url = endpoint_url + "?urn=#{cgi_urn}" # uses phone number to identify.
      end

      res = HTTParty.post(url, headers: @headers, body: body.to_json)

      case res.code
      when 201 # new person in rapidpro
        if @person.rapidpro_uuid.blank?
          @person.rapidpro_uuid = res.parsed_response["uuid"]
          @person.save # this calls the rapidpro update again, for the other attributes
        end
        true
      when 429 # throttled
        retry_delay = res.headers["retry-after"].to_i + 5
        RapidproUpdateJob.perform_in(retry_delay, id) # re-queue job
      when 200 # happy response
        if res.parsed_response.present? && @person.rapidpro_uuid.blank?
          @person.rapidpro_uuid = res.parsed_response["uuid"]
        end
        @person.save # this calls the rapidpro update again, for the other attributes
        true
      when 400
        raise "error: #{res.body}"
      else
        raise "error: #{res.code}, #{res.body}"
      end
    end
  end
end
