# frozen_string_literal: true

class AddBatchIdToGiftCards < ActiveRecord::Migration[4.2]
  def change
    add_column :gift_cards, :batch_id, :string
  end
end
