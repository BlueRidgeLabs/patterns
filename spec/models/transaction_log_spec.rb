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

require 'rails_helper'

describe TransactionLog do
  describe 'valid transactions' do
    let(:admin_user) { FactoryBot.create(:user, :admin) }
    let(:budget) { admin_user.budget }
    let(:user) { FactoryBot.create(:user) }
    let(:other_budget) { user.budget }

    it 'tops up' do
      described_class.create(amount: 100,
                             transaction_type: 'Topup',
                             recipient_type: 'Budget',
                             recipient_id: budget.id,
                             from_id: admin_user.id,
                             from_type: 'User',
                             user_id: admin_user.id)
      budget.reload
      expect(budget.amount.to_s).to eq('100.00')

      described_class.create(amount: 100,
                             transaction_type: 'Topup',
                             recipient_type: 'Budget',
                             recipient_id: budget.id,
                             from_id: admin_user.id,
                             from_type: 'User',
                             user_id: admin_user.id)
      budget.reload
      expect(budget.amount.to_s).to eq('200.00')
    end

    it 'transfers' do
      # topping up
      described_class.create(amount: 100,
                             transaction_type: 'Topup',
                             recipient_type: 'Budget',
                             recipient_id: budget.id,
                             from_id: admin_user.id,
                             from_type: 'User',
                             user_id: admin_user.id)

      # transfering
      described_class.create(amount: 100,
                             transaction_type: 'Transfer',
                             recipient_type: 'Budget',
                             recipient_id: other_budget.id,
                             from_id: budget.id,
                             from_type: 'Budget',
                             user_id: admin_user.id)

      budget.reload
      other_budget.reload
      expect(budget.amount.to_s).to eq('0.00')
      expect(other_budget.amount.to_s).to eq('100.00')
    end
  end

  describe 'invalid transactions' do
    let(:admin_user) { FactoryBot.create(:user, :admin) }
    let(:user) { FactoryBot.create(:user) }
    let(:budget) { user.budget }
    let(:other_user) { FactoryBot.create(:user) }
    let(:other_budget) { other_user.budget }

    it 'cannot top up as non-admin' do
      tl = described_class.new(amount: 100,
                               transaction_type: 'Topup',
                               # all recipients here are budgets. No Digital Gifts
                               recipient_type: 'Budget',
                               recipient_id: budget.id,
                               from_id: user.id,
                               from_type: 'User',
                               user_id: user.id)
      expect(tl.valid?).to eq(false)
      expect(tl.errors.messages[:transaction_type]).to eq(['not admin, likely.'])
    end

    it 'insufficient budget' do
      tl = described_class.new(amount: 100,
                               transaction_type: 'Transfer',
                               recipient_type: 'Budget',
                               recipient_id: other_budget.id,
                               from_id: budget.id,
                               from_type: 'Budget',
                               user_id: admin_user.id)

      expect(tl.valid?).to eq(false)
      expect(tl.errors.messages[:amount]).to eq(['insufficient budget'])
    end
  end

  xdescribe 'digital gifts' do
    # this is necessary. We'll need a factory here, I think.
  end
end
