# frozen_string_literal: true

class Notifiactionstousers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :new_person_notification, :boolean, default: false
  end
end
