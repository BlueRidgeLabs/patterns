# frozen_string_literal: true

# == Schema Information
#
# Table name: gift_cards
#
#  id               :bigint(8)        not null, primary key
#  full_card_number :string(255)
#  expiration_date  :string(255)
#  sequence_number  :integer
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

require "faker"
FactoryBot.define do
  factory :gift_card do
    sequence(:sequence_number) { |n| n }
    expiration_date "05/20"
    user
    created_by 1
    batch_id { Faker::Number.number(digits: 8) }
    amount_cents 2500
    amount_currency "USD"
    active

    trait :active do
      status "active"
      full_card_number { CreditCardValidations::Factory.random(:mastercard) }
      secure_code { Faker::Number.number(digits: 3) }
    end

    trait :preloaded do
      full_card_number nil
      secure_code nil
      status "preload"
    end
  end
end
