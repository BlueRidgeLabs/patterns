require 'faker'

FactoryBot.define do
  factory :transaction_log do
    trait :topup do
      amount 100
      user(:admin)
      recipient_type 'Budget'
      recipient_id { user.budget.id }
      transaction_type 'Topup'
      from_type 'User'
      from_id { user.id }
    end

    trait :transfer do
      transient do
        other_user { user }
      end
      amount 100
      user(:admin)
      recipient_type 'Budget'
      recipient_id { other_user.budget.id }
      transaction_type 'Transfer'
      from_type 'Budget'
      from_id { user.budget.id }
    end
  end
end
