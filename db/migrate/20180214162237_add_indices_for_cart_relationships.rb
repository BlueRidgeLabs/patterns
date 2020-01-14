# frozen_string_literal: true

class AddIndicesForCartRelationships < ActiveRecord::Migration[5.1]
  def change
    # add_index :carts_users, [:user_id, :cart_id], unique: true
    # add_index :carts_people, [:person_id, :cart_id], unique: true
  end
end
