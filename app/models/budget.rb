# frozen_string_literal: true

# == Schema Information
#
# Table name: budgets
#
#  id              :bigint(8)        not null, primary key
#  amount_cents    :integer          default(0), not null
#  amount_currency :string(255)      default("USD"), not null
#  team_id         :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Budget < ApplicationRecord
  has_paper_trail
  monetize :amount_cents
  belongs_to :team
  has_many :users, through: :team
  validates :team_id, uniqueness: true
  delegate :name, to: :team

  has_many :debits, -> { where(from_type: 'Budget') },
           class_name: 'TransactionLog',
           foreign_key: 'from_id'

  has_many :credits, -> { where(recipient_type: 'Budget') },
           class_name: 'TransactionLog',
           foreign_key: 'recipient_id'

  def transactions
    credits + debits
  end
end
