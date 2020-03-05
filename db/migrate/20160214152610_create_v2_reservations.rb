# frozen_string_literal: true

class CreateV2Reservations < ActiveRecord::Migration[4.2]
  def change
    create_table :v2_reservations do |t|
      t.integer  :time_slot_id
      t.integer  :person_id
    end
  end
end
