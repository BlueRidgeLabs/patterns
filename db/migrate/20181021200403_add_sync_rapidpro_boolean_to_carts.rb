# frozen_string_literal: true

class AddSyncRapidproBooleanToCarts < ActiveRecord::Migration[5.2]
  def change
    add_column :carts, :rapidpro_sync, :boolean, default: false
  end
end
