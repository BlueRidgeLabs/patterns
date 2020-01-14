# frozen_string_literal: true

class ChangeGiftCardExpDateToString < ActiveRecord::Migration[4.2]
  def change
    change_column :gift_cards, :expiration_date, :string
  end
end
