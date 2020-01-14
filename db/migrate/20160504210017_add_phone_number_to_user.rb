# frozen_string_literal: true

class AddPhoneNumberToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :phone_number, :string
  end
end
