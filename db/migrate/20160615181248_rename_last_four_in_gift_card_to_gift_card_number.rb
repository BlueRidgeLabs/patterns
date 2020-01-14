# frozen_string_literal: true

class RenameLastFourInGiftCardToGiftCardNumber < ActiveRecord::Migration[4.2]
  def change
    rename_column :gift_cards, :last_four, :gift_card_number
  end
end
