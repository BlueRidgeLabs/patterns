# frozen_string_literal: true

class RenameProxyIdToSequenceAndChangeToInt < ActiveRecord::Migration[5.2]
  def change
    rename_column :gift_cards, :proxy_id, :sequence_number
    change_column :gift_cards, :sequence_number, :integer
  end
end
