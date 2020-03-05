# frozen_string_literal: true

class AddLandlineToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :landline, :string, default: nil
  end
end
