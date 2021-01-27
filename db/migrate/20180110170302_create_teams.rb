# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[5.1]
  def change
    create_table :teams do |t|
      t.string :name
      t.string :finance_code
      t.text :description
      t.timestamps
    end
    add_column :users, :team_id, :bigint
    # add_foreign_key :users, :teams # breaks things.
  end
end
