# frozen_string_literal: true

class AddFormTypeToTwilioWufoos < ActiveRecord::Migration[4.2]
  def change
    add_column :twilio_wufoos, :form_type, :string
  end
end
