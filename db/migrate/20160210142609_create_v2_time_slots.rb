# frozen_string_literal: true

class CreateV2TimeSlots < ActiveRecord::Migration[4.2]
  def change
    create_table :v2_time_slots do |t|
      t.integer  :event_id
      t.datetime :start_time
      t.datetime :end_time
    end
  end
end
