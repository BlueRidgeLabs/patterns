require 'faker'

FactoryBot.define do
  factory :transaction_log do
    trait :topup do
      amount 100
      user(:admin)
      recipient_type 'Budget'
      transaction_type 'Topup'  
      from_type 'User'
    end
  end
end
