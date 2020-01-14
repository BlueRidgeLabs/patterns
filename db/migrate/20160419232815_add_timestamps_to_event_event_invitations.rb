# frozen_string_literal: true

class AddTimestampsToEventEventInvitations < ActiveRecord::Migration[4.2]
  def change
    change_table(:v2_event_invitations, &:timestamps)
    change_table(:v2_events, &:timestamps)
  end
end
