# frozen_string_literal: true

class AddIdToCartsPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :carts_people, :id, :primary_key
  end
end
