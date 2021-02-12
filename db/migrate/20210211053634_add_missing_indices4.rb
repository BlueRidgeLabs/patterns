# frozen_string_literal: true

class AddMissingIndices4 < ActiveRecord::Migration[6.0]
  def change
    add_index :users, :team_id
  end
end
