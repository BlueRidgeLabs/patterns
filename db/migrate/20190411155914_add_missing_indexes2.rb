class AddMissingIndexes2 < ActiveRecord::Migration[5.2]
  def change
    add_index :activation_calls, :gift_card_id
    add_index :budgets, :team_id
    add_index :carts_people, :cart_id
    add_index :carts_people, :person_id
    add_index :carts_users, :cart_id
    add_index :carts_users, :user_id
    add_index :cash_cards, :person_id
    add_index :cash_cards, :user_id
    add_index :comments, [:commentable_id, :commentable_type]
    add_index :digital_gifts, :reward_id
    add_index :digital_gifts, :user_id
    add_index :gift_cards, :user_id
    add_index :rewards, :person_id
    add_index :rewards, :team_id
    add_index :rewards, :user_id
    add_index :rewards, [:giftable_id, :giftable_type]
    add_index :rewards, [:rewardable_id, :rewardable_type]
  end
end
