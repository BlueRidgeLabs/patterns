# frozen_string_literal: true

class CreateActivationCalls < ActiveRecord::Migration[5.2]
  def change
    create_table :activation_calls do |t|
      t.integer :card_activation_id
      t.string :sid
      t.string :transcript
      t.string :audio_url
      t.string :type
      t.timestamps
    end
  end
end
