# frozen_string_literal: true

class AddScreeningToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :screening_status, :string, default: 'new'
    add_column :people, :phone_confirmed, :boolean, default: false
    add_column :people, :email_confirmed, :boolean, default: false
    add_column :people, :confirmation_sent, :boolean, default: false
    add_column :people, :welcome_sent, :boolean, default: false
    add_column :people, :participation_level, :string, default: 'new'
  end
end
