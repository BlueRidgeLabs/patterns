# frozen_string_literal: true

class AddIndicesForResearchAndInvitations < ActiveRecord::Migration[4.2]
  def change
    add_index :invitations, :person_id
    add_index :invitations, :research_session_id
    add_index :research_sessions, :user_id
  end
end
