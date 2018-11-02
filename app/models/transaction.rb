# frozen_string_literal: true

# == Schema Information
#
# Table name: transactions
#
#  id              :bigint(8)        not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  from_id         :integer
#  from_type       :string(255)
#  to_id           :integer
#  to_type         :string(255)
#  notes           :string(255)
#  user_id         :integer
#  amount_cents    :integer          default(0), not null
#  amount_currency :integer          default(0), not null
#

# stores all transactions in a log
class Transaction < ApplicationRecord
  has_paper_trail
  monetize :amount_cents
  after_commit :update_budgets
  validate :sufficient_budget?
  validates :from_type,
    inclusion: {
      in: %w[Budget GiftCard]
    }
  validates :to_type,
    inclusion: {
      in: %w[Budget GiftCard]
    }

  def update_budgets
    # do we do this here?
    # where we add and remove from the appropriate budgets
  end

  private

    # is there sufficient budget for the transaction to go through
    # do we do this here?
    def sufficient_budget?
      # find the from_type class and instantiate
      klass = from_type.classify.constantize
      creditor = klass.find(from_id)
      return false if creditor.nil?

      creditor.amount >= amount # should always have an amount
    end
end