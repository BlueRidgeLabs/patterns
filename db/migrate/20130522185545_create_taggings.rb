# frozen_string_literal: true

class CreateTaggings < ActiveRecord::Migration[4.2]
  def change
    create_table :taggings do |t|
      t.string :taggable_type
      t.integer :taggable_id
      t.integer :created_by

      t.timestamps
    end
  end
end
