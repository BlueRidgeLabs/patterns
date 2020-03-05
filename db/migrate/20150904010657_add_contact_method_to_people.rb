# frozen_string_literal: true

class AddContactMethodToPeople < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :preferred_contact_method, :string
  end
end
