# frozen_string_literal: true

class AddIdToCartsUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :carts_users, :id, :primary_key
  end
end
