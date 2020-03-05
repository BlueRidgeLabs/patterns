# frozen_string_literal: true

class AddsecureCodeAndActiveStatusToGiftCards < ActiveRecord::Migration[4.2]
  def change
    add_column :gift_cards, :active, :boolean, default: false
    add_column :gift_cards, :secure_code, :string
  end
end
