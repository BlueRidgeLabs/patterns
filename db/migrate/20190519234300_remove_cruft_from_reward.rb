# frozen_string_literal: true

class RemoveCruftFromReward < ActiveRecord::Migration[5.2]
  def change
    remove_column :rewards, :gift_card_number
    remove_column :rewards, :expiration_date
    remove_column :rewards, :batch_id
    remove_column :rewards, :sequence_number
    remove_column :rewards, :active
    remove_column :rewards, :secure_code
  end
end
