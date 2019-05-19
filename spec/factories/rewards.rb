# == Schema Information
#
# Table name: rewards
#
#  id              :integer          not null, primary key
#  person_id       :integer
#  notes           :string(255)
#  created_by      :integer
#  reason          :integer
#  amount_cents    :integer          default(0), not null
#  amount_currency :string(255)      default("USD"), not null
#  giftable_id     :integer
#  giftable_type   :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  team_id         :bigint(8)
#  finance_code    :string(255)
#  user_id         :integer
#  rewardable_type :string(255)
#  rewardable_id   :bigint(8)
#

FactoryBot.define do
  factory :reward do
    user
    person
    team_id { user.team.id }
    finance_code { user.team.finance_code }
    
    trait :gift_card do
      after(:build) do |reward|
        reward.rewardable = build(:gift_card)
      end
    end

    trait :digital_gift do
      after(:build) do |reward|
        reward.rewardable = build(:digital_gift)
      end
    end
    
    after(:build) do |reward|
      reward.giftable = build(:invitation)
    end
    
    after(:create) do |reward|
      reward.giftable.save
      reward.rewardable.save
    end
  end
end

