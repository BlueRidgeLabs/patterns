# frozen_string_literal: true

class MoveFromEmailToIdInEventInvitations < ActiveRecord::Migration[4.2]
  def change
    rename_column :v2_event_invitations, :email_addresses, :people_ids
  end
end
