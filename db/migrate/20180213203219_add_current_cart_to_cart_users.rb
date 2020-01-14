# frozen_string_literal: true

class AddCurrentCartToCartUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :carts_users, :current_cart, :boolean, default: false
  end
end
