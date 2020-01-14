# frozen_string_literal: true

json.array!(@rewards) do |reward|
  json.extract! reward, :rewardable_type, :rewardable_id, :giftable_type, :giftable_id, :user_id, :person_id, :notes, :created_by, :reason
  json.url reward_url(reward, format: :json)
end
