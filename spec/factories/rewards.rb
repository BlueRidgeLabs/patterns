# frozen_string_literal: true

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
    giftable { build(:invitation) }
    person { giftable.person }

    created_by { user.id }
    team_id { user.team.id }
    finance_code { user.team.finance_code }
    reason 2
    trait :gift_card do
      rewardable { build(:gift_card, user: user, created_by: user.id) }
    end

    trait :digital_gift do
      rewardable { build(:digital_gift, :funded, user: user, created_by: user.id) }
    end

    # after(:build) do |reward|
    #   reward.giftable = build(:invitation, person: reward.person)
    # end

    after(:create) do |reward|
      reward.giftable.save
      reward.rewardable.save
    end
  end
end
