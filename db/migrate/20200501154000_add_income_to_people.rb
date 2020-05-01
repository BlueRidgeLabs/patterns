# frozen_string_literal: true

class AddIncomeToPeople < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :income_level, :string
  end
end
