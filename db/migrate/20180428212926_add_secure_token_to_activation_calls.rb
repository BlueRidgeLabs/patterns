# frozen_string_literal: true

class AddSecureTokenToActivationCalls < ActiveRecord::Migration[5.2]
  def change
    add_column :activation_calls, :token, :string
    add_index :activation_calls, :token, unique: true
  end
end
