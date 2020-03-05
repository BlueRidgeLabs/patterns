# frozen_string_literal: true

class CreateCashCards < ActiveRecord::Migration[5.2]
  def change
    create_table :cash_cards do |t|
      t.monetize :amount
      t.string  :notes
      t.integer :reward_id
      t.integer :person_id
      t.integer :created_by, null: false
      t.integer :user_id
      t.text :legacy_attributes
      t.timestamps
    end
  end
end
