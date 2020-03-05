# frozen_string_literal: true

class PeopleActiveBoolean < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :active, :boolean, default: true
    add_column :people, :deactivated_at, :datetime
    add_column :people, :deactivated_method, :string
  end
end
