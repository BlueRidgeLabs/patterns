# frozen_string_literal: true

class RapidproGroupJob
  include Sidekiq::Worker
  sidekiq_options retry: 5
  sidekiq_options queue: 'rapidpro'
  # two possible actions for groups: create or delete.
  # need another job which is add/remove to group for individuals.
  # works like so: if cart doesnt' have rapidpro UUID, then create group on RP
  # if cart has rapidpro UUID, check if it exists in RP, if not, create
  # finally, use contact actions to sync up whole group.

  # for delete the group, pull down all UUIDS, use contact actions to remove
  # all UUID from group, and then when empty, delete group and set rapidpro_uuid
  # to nil
  # for individual person adds/removes use other job

  def perform(cart_id, action)
    @headers = { 'Authorization' => "Token #{ENV['RAPIDPRO_TOKEN']}",
                 'Content-Type' => 'application/json' }
    @base_url = 'https://rapidpro.brl.nyc/api/v2/'
    Rails.logger.info "[RapidProGroup] job enqueued: cart: #{cart_id}, action: #{action}"
    @cart = Cart.find(cart_id)
    case action
    when 'create'
      create
    when 'delete'
      delete
    end
  end

  def create
    return unless @cart.rapidpro_sync # perhaps cart is no longer synced

    url = @base_url + 'groups.json'

    if @cart.rapidpro_uuid.present?
      @cart.rapidpro_uuid = nil unless find_group
    end

    if @cart.rapidpro_uuid.nil?
      # create group and save uuid
      res = HTTParty.post(url, headers: @headers, body: { name: @cart.name }.to_json)
      case res.code
      when 201 # new group in rapidpro
        # update column to skip callbacks
        @cart.rapidpro_uuid = res.parsed_response['uuid']
        @cart.save
      when 429 # throttled
        retry_delay = res.headers['retry-after'].to_i + 5
        RapidproGroupJob.perform_in(retry_delay, @cart.id, 'create') # re-queue job
        return
      else
        Rails.logger.error res.code
        raise 'error'
      end
    end
    # need a delay for rapidpro to catch up, maybe?
    sleep(1) until find_group
    people_ids = @cart.people.where.not(rapidpro_uuid: nil, phone_number: nil).pluck(:id)
    RapidproPersonGroupJob.perform_async(people_ids, @cart.id, 'add')
  end

  def delete
    return if @cart.rapidpro_uuid.blank?

    res = HTTParty.delete(@base_url + "groups.json?uuid=#{@cart.rapidpro_uuid}", headers: @headers)
    case res.code
    when 204
      @cart.rapidpro_uuid = nil
      @cart.save
      true
    when 404 # it never was created on rapidpro in the first place.
      @cart.rapidpro_uuid = nil
      @cart.save
      true
    when 429
      retry_delay = res.headers['retry-after'].to_i + 5
      RapidproGroupJob.perform_in(retry_delay, @cart.id, 'delete') # re-queue job
    else
      raise "delete error:#{@cart.id}, code: #{res.code}"
    end
  end

  def find_group
    url = @base_url + 'groups.json'
    found = false
    while found == false
      res = HTTParty.get(url, headers: @headers)
      found = res.parsed_response['results'].find { |r| r['uuid'] == @cart.rapidpro_uuid }.present?
      if res.parsed_response['next'].nil?
        break
      else
        url = res.parsed_response['next']
      end
    end
    found
  end
end
