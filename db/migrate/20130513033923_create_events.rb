# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :events do |t|
      t.string :name
      t.text :description
      t.datetime :starts_at
      t.datetime :ends_at
      t.text :location
      t.text :address
      t.integer :capacity
      t.integer :application_id

      t.timestamps
    end
  end
end
