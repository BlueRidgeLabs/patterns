# frozen_string_literal: true

# == Schema Information
#
# Table name: transaction_logs
#
#  id               :bigint(8)        not null, primary key
#  from_id          :integer
#  from_type        :string(255)
#  recipient_id     :integer
#  recipient_type   :string(255)
#  transaction_type :string(255)
#  user_id          :integer
#  amount_cents     :integer          default(0), not null
#  amount_currency  :string(255)      default("USD"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

# should we have an opening balance,
# closing balance and remote balance?

# all transactions in a log
class TransactionLog < ApplicationRecord
  has_paper_trail
  monetize :amount_cents
  after_create :update_budgets

  belongs_to :user

  validate :logic_validation

  validates :from_id, presence: true
  validates :from_type, presence: true

  belongs_to :from, polymorphic: true
  belongs_to :recipient, polymorphic: true

  default_scope { includes(:recipient, :from) }

  validates :transaction_type, inclusion: { in: %w[DigitalGift Transfer Topup] }

  validates :recipient_type,
            inclusion: {
              in: %w[Budget DigitalGift]
            }, allow_nil: true

  validates :from_type,
            inclusion: {
              in: %w[Budget User]
            }

  # TODO: add a "cancel" transation here.
  def update_budgets
    case transaction_type
    when 'Transfer'
      from.amount -= amount
      recipient.amount += amount
      from.save
      recipient.save
    when 'DigitalGift'
      from.amount -= amount
      from.save
    when 'Topup'
      recipient.amount += amount
      recipient.save
    end
  end

  def self.all_csv
    CSV.generate do |csv|
      csv << TransactionLog.csv_headers
      TransactionLog.all.find_each { |t| csv << t.to_csv_row }
    end
  end

  def self.csv_headers
    %w[id
       transaction_type
       from_id
       from_type
       from_name
       recipient_id
       recipient_type
       recipient_name
       amount_cents
       amount
       tremendous_order_id
       created_at
       accounting]
  end

  def to_csv_row
    [id,
     transaction_type,
     from_id,
     from_type,
     from.name,
     recipient_id,
     recipient_type,
     recipient&.name,
     amount_cents,
     amount.to_s,
     recipient.instance_of?(DigitalGift) ? recipient.order_id : '',
     created_at,
     external_accounting_value]
  end

  def external_accounting_value
    case transaction_type
    when 'TopUp'
      amount
    when 'Transfer'
      0
    when 'DigitalGift'
      (amount * -1).to_s
    end
  end

  # is there sufficient budget for the transaction recipient go through
  # do we do this here?
  def sufficient_budget?
    # topup auth handled elsewhere.
    return true if transaction_type == 'Topup'

    if from.amount.to_i < amount.to_i
      # everyone else, including admins has to have enough
      errors.add(:amount, :invalid, message: 'insufficient budget')
    else
      true
    end
  end

  def admin?
    from.admin? if from.respond_to?(:admin?)
  end

  def from_present?
    errors.add(:from_id, :invalid, message: 'from not found') if from.nil?
  end

  def correct_type?
    case transaction_type
    when 'Transfer'
      if recipient_type == 'Budget' && from_type == 'Budget' && from_id != recipient_id
        true
      else
        errors.add(:transaction_type, :invalid, message: 'Incorrect recipients')
      end
    when 'Topup'
      if recipient_type == 'Budget' && from_type == 'User' && admin? && from.team == recipient.team
        true
      else
        errors.add(:transaction_type, :invalid, message: 'not admin, likely.')
      end
    when 'DigitalGift'
      if recipient_type == 'DigitalGift' && from_type == 'Budget'
        true
      else
        errors.add(:transaction_type, :invalid, 'message: wrong types!')
      end
    end
  end

  def logic_validation
    from_present?
    sufficient_budget?
    correct_type?
  end
end
