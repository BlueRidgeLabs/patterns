# frozen_string_literal: true

class AddTagCounterCache < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :taggings_count, :integer, null: false, default: 0
  end
end
