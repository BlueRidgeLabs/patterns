# frozen_string_literal: true

class AddAmountToCardActivations < ActiveRecord::Migration[5.2]
  def change
    add_monetize :card_activations, :amount
    add_column :activation_calls, :status, :string, default: 'created'
  end
end
