# frozen_string_literal: true

class ChangeToActsAsTaggable < ActiveRecord::Migration[4.2]
  def change
    rename_table :tags, :old_tags
    rename_table :taggings, :old_taggings
    add_column :people, :cached_tag_list, :string
  end
end
