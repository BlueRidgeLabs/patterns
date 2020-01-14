# frozen_string_literal: true

class ChangeProxyIdToString < ActiveRecord::Migration[4.2]
  def change
    change_column :gift_cards, :proxy_id, :string
  end
end
