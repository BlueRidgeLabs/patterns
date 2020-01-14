# frozen_string_literal: true

class AddSecondaryAccessMethodToPeople < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :secondary_connection_id, :integer
    add_column :people, :secondary_connection_description, :string
  end
end
