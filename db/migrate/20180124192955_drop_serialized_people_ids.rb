# frozen_string_literal: true

class DropSerializedPeopleIds < ActiveRecord::Migration[5.1]
  def change
    remove_column :carts, :people_ids
  end
end
