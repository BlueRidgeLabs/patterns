# frozen_string_literal: true

class AddVerifiedToPeople < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :verified, :string
  end
end
