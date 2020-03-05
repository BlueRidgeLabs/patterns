# frozen_string_literal: true

class RenamingV2EventsToResearchSessions < ActiveRecord::Migration[4.2]
  def change
    rename_table :v2_event_invitations, :research_sessions
    rename_table :v2_reservations, :invitations
    drop_table :v2_events
    drop_table :v2_time_slots

    add_column :research_sessions, :start_datetime, :datetime
    add_column :research_sessions, :end_datetime, :datetime
    add_column :research_sessions, :sms_description, :string
    add_column :research_sessions, :type, :integer, default: 1

    remove_column :research_sessions, :date
    remove_column :research_sessions, :people_ids
    remove_column :research_sessions, :start_time
    remove_column :research_sessions, :end_time
    remove_column :research_sessions, :v2_event_id
    remove_column :research_sessions, :slot_length

    remove_column :invitations, :time_slot_id
    remove_column :invitations, :event_id
    remove_column :invitations, :user_id

    rename_column :invitations, :event_invitation_id, :research_session_id
  end
end
