# == Schema Information
#
# Table name: gift_cards
#
#  id               :bigint(8)        not null, primary key
#  full_card_number :string(255)
#  expiration_date  :string(255)
#  sequence_number  :string(255)
#  secure_code      :string(255)
#  batch_id         :string(255)
#  status           :string(255)      default("created")
#  user_id          :integer
#  reward_id        :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  amount_cents     :integer          default(0), not null
#  amount_currency  :string(255)      default("USD"), not null
#  created_by       :integer
#
require 'faker'
FactoryBot.define do
  factory :gift_card do
    full_card_number {CreditCardValidations::Factory.random(:mastercard)}
    expiration_date '05/20'
    user_id 1
    created_by 1
    status 'active'
    amount_cents 2500
    amount_currency "USD"
    secure_code {Faker::Number.number(3)}
    sequence_number {Faker::Number.number(3)}
    batch_id {Faker::Number.number(8)}
  end
end
