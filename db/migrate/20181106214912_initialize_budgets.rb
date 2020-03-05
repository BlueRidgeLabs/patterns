# frozen_string_literal: true

class InitializeBudgets < ActiveRecord::Migration[5.2]
  def change
    # initialize budgets to zero
    Team.find_each { |t| Budget.create(team_id: t.id, amount: 0) }
  end
end
