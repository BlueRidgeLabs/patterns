# frozen_string_literal: true

class CreateCardActivations < ActiveRecord::Migration[5.2]
  def change
    create_table :card_activations do |t|
      t.string :full_card_number
      t.string :expiration_date
      t.string :sequence_number
      t.string :secure_code
      t.string :batch_id
      t.string :status, default: 'created'
      t.integer :user_id
      t.integer :gift_card_id, default: nil
      t.timestamps
    end
  end
end
