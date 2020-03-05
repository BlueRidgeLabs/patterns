# frozen_string_literal: true

class ChangeLengthOfGiftCardsNumber < ActiveRecord::Migration[4.2]
  def change
    change_column :gift_cards, :gift_card_number, :integer, limit: 8
  end
end
