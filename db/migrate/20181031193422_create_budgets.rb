# frozen_string_literal: true

class CreateBudgets < ActiveRecord::Migration[5.2]
  def change
    create_table :budgets do |t|
      t.monetize :amount
      t.integer  :team_id
      t.timestamps
    end
  end
end
