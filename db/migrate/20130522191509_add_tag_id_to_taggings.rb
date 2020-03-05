# frozen_string_literal: true

class AddTagIdToTaggings < ActiveRecord::Migration[4.2]
  def change
    add_column :taggings, :tag_id, :integer
  end
end
