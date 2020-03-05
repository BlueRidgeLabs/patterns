# frozen_string_literal: true

class CreateDigitalGifts < ActiveRecord::Migration[5.2]
  def change
    create_table :digital_gifts do |t|
      t.text :order_details
      t.integer :created_by, null: false
      t.integer :user_id
      t.integer :person_id
      t.integer :reward_id
      t.string :aasm_state
      t.string :external_id
      t.string :order_id
      t.string :gift_id
      t.text :link
      t.monetize :amount
      t.monetize :fee
      t.timestamps
    end
  end
end
