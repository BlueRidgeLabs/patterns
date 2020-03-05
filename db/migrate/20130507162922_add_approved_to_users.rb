# frozen_string_literal: true

class AddApprovedToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :approved, :boolean, default: false, null: false
  end
end
