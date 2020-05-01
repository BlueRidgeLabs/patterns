# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id           :bigint(8)        not null, primary key
#  name         :string(255)
#  finance_code :string(255)
#  description  :text(16777215)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Team < ApplicationRecord
  FINANCE_CODES = %w[BRL CATA1 CATA2 FELL].freeze
  has_many :users
  has_many :research_sessions, through: :users
  has_many :rewards
  has_one :budget
  has_many :debits, through: :budget
  has_many :credits, through: :budget
  validates :finance_code, inclusion: { in: FINANCE_CODES }
  default_scope { includes(:rewards) }

  after_create :make_budget

  def rewards_total(since = Time.zone.today.beginning_of_year - 1.day)
    raise ArgumentError if since.class != Date

    total = rewards.where('created_at > ?', since).sum(:amount_cents)
    Money.new(total, 'USD')
  end

  def reward_by_finance_code(finance_code)
    total = rewards.where(finance_code: finance_code).sum(:amount_cents)
    Money.new(total, 'USD')
  end

  def available_budget
    budget.amount
  end

  delegate :transactions, to: :budget

  private

  def make_budget
    Budget.create(team_id: id)
  end
end
