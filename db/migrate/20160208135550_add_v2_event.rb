# frozen_string_literal: true

class AddV2Event < ActiveRecord::Migration[4.2]
  def change
    create_table :v2_events do |t|
      t.integer :user_id
      t.string  :description
    end
  end
end
