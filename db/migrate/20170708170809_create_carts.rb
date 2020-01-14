# frozen_string_literal: true

class CreateCarts < ActiveRecord::Migration[4.2]
  def change
    create_table :carts do |t|
      t.string :name, default: 'default'
      t.integer :user_id, null: false
      t.string :people_ids, default: [].to_json
      t.timestamps null: false
      t.index :user_id
    end
  end
end
