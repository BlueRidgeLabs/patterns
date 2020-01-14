# frozen_string_literal: true

class AddCartCounterCache < ActiveRecord::Migration[5.2]
  def change
    add_column :carts, :people_count, :integer, default: 0
  end
end
