# frozen_string_literal: true

class AddTitleToEventInvitation < ActiveRecord::Migration[4.2]
  def change
    add_column :v2_event_invitations, :title, :string
  end
end
