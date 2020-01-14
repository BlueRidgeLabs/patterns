# frozen_string_literal: true

class MoveOldRewardsToNewRecords < ActiveRecord::Migration[5.2]
  def change
    Reward.reset_column_information

    # Reward.find_each(10) do |r|
    #   r.user_id = r.created_by if r.user_id.nil?
    #   r.team_id = 1 if r.team_id.nil? # again, old gift cards

    #   gc = GiftCard.find_by(reward_id: r.id)

    #   if gc.present?
    #     r.rewardable_type = 'GiftCard'
    #     r.rewardable_id = gc.id
    #     c = nil
    #   else
    #     c = CashCard.new()
    #     c.amount = r.amount
    #     c.reward_id = r.id
    #     c.notes = r.notes
    #     c.person_id = r.person_id
    #     c.user_id = r.user_id
    #     c.created_by = r.created_by
    #     c.legacy_attributes = r.attributes.to_json
    #     c.save
    #     r.rewardable_type = 'CashCard'
    #     r.rewardable_id = c.id
    #   end

    #   if r.giftable.nil?
    #     # these are old giftcards
    #     # not sure what to do with them. this is a hack
    #     r.giftable_id = 2
    #     r.giftable_type = 'User'
    #   end

    #   unless r.save
    #     puts "invalid #{r.id}"
    #     # reward isn't valud, don't make the cash card
    #     c.destroy if c.present?
    #   end
    # end
  end
end
