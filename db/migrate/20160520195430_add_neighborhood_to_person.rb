# frozen_string_literal: true

class AddNeighborhoodToPerson < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :neighborhood, :string
  end
end
