# == Schema Information
#
# Table name: rewards
#
#  id               :integer          not null, primary key
#  gift_card_number :string(255)
#  expiration_date  :string(255)
#  person_id        :integer
#  notes            :string(255)
#  created_by       :integer
#  reason           :integer
#  amount_cents     :integer          default(0), not null
#  amount_currency  :string(255)      default("USD"), not null
#  giftable_id      :integer
#  giftable_type    :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  batch_id         :string(255)
#  sequence_number  :integer
#  active           :boolean          default(FALSE)
#  secure_code      :string(255)
#  team_id          :bigint(8)
#  finance_code     :string(255)
#  user_id          :integer
#  rewardable_type  :string(255)
#  rewardable_id    :bigint(8)
#

FactoryBot.define do
  factory :reward do
    user
    person
    team_id { user.team.id }
    finance_code { user.team.finance_code }

     after(:build) do |reward|
      reward.giftable = build(:invitation)
      reward.rewardable = build(:gift_card)
    end

    after(:create) do |reward|
      reward.giftable.save
      reward.rewardable.save
    end
  end
end

