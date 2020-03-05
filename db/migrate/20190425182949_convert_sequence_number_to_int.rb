# frozen_string_literal: true

class ConvertSequenceNumberToInt < ActiveRecord::Migration[5.2]
  def change
    change_column :gift_cards, :sequence_number, :integer
  end
end
