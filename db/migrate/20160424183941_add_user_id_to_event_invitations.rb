# frozen_string_literal: true

class AddUserIdToEventInvitations < ActiveRecord::Migration[4.2]
  def change
    add_column :v2_event_invitations, :user_id, :integer
  end
end
