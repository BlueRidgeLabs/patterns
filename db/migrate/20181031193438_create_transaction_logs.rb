# frozen_string_literal: true

class CreateTransactionLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :transaction_logs do |t|
      t.integer :from_id
      t.string :from_type
      t.integer :recipient_id
      t.string :recipient_type

      t.string :transaction_type
      t.integer :user_id, index: true
      t.monetize :amount
      t.timestamps
    end

    add_index :transaction_logs, %i[from_id from_type]
    add_index :transaction_logs, %i[recipient_id recipient_type]
  end
end
