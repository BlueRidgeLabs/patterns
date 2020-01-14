# frozen_string_literal: true

class AddStatusToTwilioWufoos < ActiveRecord::Migration[4.2]
  def change
    add_column :twilio_wufoos, :status, :boolean, null: false, default: false
  end
end
