# frozen_string_literal: true

class AddingBufferToEventInvitations < ActiveRecord::Migration[4.2]
  def change
    add_column :v2_event_invitations, :buffer, :integer, default: 0, null: false
  end
end
