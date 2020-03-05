# frozen_string_literal: true

class CreateEventInvitations < ActiveRecord::Migration[4.2]
  def change
    create_table :v2_event_invitations do |t|
      t.integer :v2_event_id
      t.string :email_addresses
      t.string :description
      t.string :slot_length
      t.string :date
      t.string :start_time
      t.string :end_time
    end
  end
end
