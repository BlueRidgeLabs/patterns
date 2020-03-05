# frozen_string_literal: true

class ChangeGiftCardNumberToString < ActiveRecord::Migration[4.2]
  def change
    change_column :gift_cards, :gift_card_number, :string
  end
end
