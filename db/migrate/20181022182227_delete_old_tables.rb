# frozen_string_literal: true

class DeleteOldTables < ActiveRecord::Migration[5.2]
  def change
    drop_table :reservations
    drop_table :events
    drop_table :programs
    drop_table :applications
    drop_table :submissions
    drop_table :twilio_wufoos
    drop_table :old_taggings
    drop_table :old_tags
  end
end
