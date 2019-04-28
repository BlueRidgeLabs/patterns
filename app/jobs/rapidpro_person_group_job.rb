# frozen_string_literal: true

class RapidproPersonGroupJob
  include Sidekiq::Worker
  sidekiq_options retry: 5

  # two possible actions for groups: create or delete.
  # need another job which is add/remove to group for individuals.
  # works like so: if cart doesnt' have rapidpro UUID, then create group on RP
  # if cart has rapidpro UUID, check if it exists in RP, if not, create
  # finally, use contact actions to sync up whole group.

  # for delete the group, pull down all UUIDS, use contact actions to remove
  # all UUID from group, and then when empty, delete group and set rapidpro_uuid
  # to nil
  # for individual person adds/removes use other job

  def perform(people_ids, cart_id, action)
    @headers = { 'Authorization' => "Token #{ENV['RAPIDPRO_TOKEN']}",
                 'Content-Type'  => 'application/json' }
    @base_url = 'https://rapidpro.brl.nyc/api/v2/'
    Rails.logger.info "[RapidProPersonGroup] job enqueued: cart: #{cart_id}, action: #{action}"
    @cart = Cart.find(cart_id)

    return unless @cart.rapidpro_sync # perhaps cart is no longer synced

    @people_uuids = Person.where(id: people_ids).tagged_with('not dig', exclude: true).pluck(:rapidpro_uuid).compact
    @action = action
    raise 'cart not in rapidpro' if @cart.rapidpro_uuid.nil?
    raise 'invalid action' unless %w[add remove].include? action

    url = @base_url + 'contact_actions.json'
    not_throttled = true
    while @people_uuids.size.positive? && not_throttled
      uuids = @people_uuids.pop(100)
      body = { 'action': @action, contacts: uuids, group: @cart.rapidpro_uuid }
      res = HTTParty.post(url, headers: @headers, body: body.to_json)
      next unless res.code == 429 # throttled

      retry_delay = res.headers['retry-after'].to_i + 5
      pids = Person.where(rapidpro_uuid: @people_uuids)
      retry_later(pids, retry_delay)
      not_throttled = false
    end
  end

  def retry_later(pids, retry_delay)
    RapidProPersonGroupJob.perform_in(retry_delay, pids, @cart.id, @action)
  end

end
