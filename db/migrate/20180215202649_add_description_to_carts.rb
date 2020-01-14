# frozen_string_literal: true

class AddDescriptionToCarts < ActiveRecord::Migration[5.1]
  def change
    add_column :carts, :description, :text
  end
end
