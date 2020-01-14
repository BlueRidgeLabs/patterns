# frozen_string_literal: true

class AddProxyidToGiftcards < ActiveRecord::Migration[4.2]
  def change
    add_column :gift_cards, :proxy_id, :integer
  end
end
