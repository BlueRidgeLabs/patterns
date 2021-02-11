# frozen_string_literal: true

class CreateEmailLinks < ActiveRecord::Migration[6.0]
  def change
    create_table :email_links do |t|
      t.string :token
      t.datetime :expires_at
      t.references :user, null: false
      t.timestamps
    end
  end
end
