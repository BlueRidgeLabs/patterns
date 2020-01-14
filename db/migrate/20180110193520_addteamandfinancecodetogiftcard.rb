# frozen_string_literal: true

class Addteamandfinancecodetogiftcard < ActiveRecord::Migration[5.1]
  def change
    add_column :gift_cards, :team_id, :bigint, default: nil
    add_column :gift_cards, :finance_code, :string, default: nil
  end
end
