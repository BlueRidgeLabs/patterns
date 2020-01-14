# frozen_string_literal: true

class CreateMailchimpExports < ActiveRecord::Migration[4.2]
  def change
    create_table :mailchimp_exports do |t|
      t.string :name
      t.text :body
      t.integer :created_by

      t.timestamps
    end
  end
end
