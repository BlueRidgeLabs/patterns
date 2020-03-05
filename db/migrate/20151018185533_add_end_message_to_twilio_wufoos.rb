# frozen_string_literal: true

class AddEndMessageToTwilioWufoos < ActiveRecord::Migration[4.2]
  def change
    add_column :twilio_wufoos, :end_message, :string
  end
end
