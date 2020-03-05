# frozen_string_literal: true

class DropCachedTagList < ActiveRecord::Migration[5.1]
  def change
    remove_column :people, :cached_tag_list
  end
end
