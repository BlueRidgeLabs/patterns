# frozen_string_literal: true

class TurnLinkSentToBoolean < ActiveRecord::Migration[5.2]
  def change
    change_column :digital_gifts, :sent, :boolean
    add_column :digital_gifts, :sent_at, :datetime
    add_column :digital_gifts, :sent_by, :integer
  end
end
