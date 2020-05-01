# frozen_string_literal: true

class AddBirthyearRaceToPeople < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :birth_year, :integer, default: nil
    add_column :people, :race_ethnicity, :text
  end
end
