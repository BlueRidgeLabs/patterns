# frozen_string_literal: true

class AddIndexToGiftCardsReason < ActiveRecord::Migration[4.2]
  def change
    add_index :gift_cards, :reason, name: 'gift_reason_index'
  end
end
