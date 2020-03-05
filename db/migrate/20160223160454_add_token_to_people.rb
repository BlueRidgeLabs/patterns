# frozen_string_literal: true

class AddTokenToPeople < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :token, :string
  end
end
