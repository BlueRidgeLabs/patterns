# frozen_string_literal: true

class ChangingGiftCardsToRewards < ActiveRecord::Migration[5.2]
  def change
    rename_table :gift_cards, :rewards
    rename_table :card_activations, :gift_cards
    add_column :rewards, :user_id, :integer
    add_reference :rewards, :rewardable, polymorphic: true, index: true
    rename_column :activation_calls, :card_activation_id, :gift_card_id
    rename_column :gift_cards, :gift_card_id, :reward_id
  end
end
