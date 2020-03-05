# frozen_string_literal: true

class AddFieldsToPerson < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :signup_ip,   :string
    add_column :people, :signup_at,   :datetime
    add_column :people, :voted,       :string
    add_column :people, :called_311,  :string
  end
end
