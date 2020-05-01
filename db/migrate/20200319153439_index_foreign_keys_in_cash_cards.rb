# frozen_string_literal: true

class IndexForeignKeysInCashCards < ActiveRecord::Migration[6.0]
  def change
    add_index :cash_cards, :reward_id
  end
end
