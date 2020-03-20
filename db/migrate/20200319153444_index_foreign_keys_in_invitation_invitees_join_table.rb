class IndexForeignKeysInInvitationInviteesJoinTable < ActiveRecord::Migration[6.0]
  def change
    add_index :invitation_invitees_join_table, :event_invitation_id
    add_index :invitation_invitees_join_table, :person_id
  end
end
