# frozen_string_literal: true

class AddTagCounterCacheToPerson < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :tag_count_cache, :integer, default: 0
  end
end
