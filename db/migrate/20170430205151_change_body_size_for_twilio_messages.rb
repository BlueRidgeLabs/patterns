# frozen_string_literal: true

class ChangeBodySizeForTwilioMessages < ActiveRecord::Migration[4.2]
  def change
    change_column :twilio_messages, :body, :text
  end
end
