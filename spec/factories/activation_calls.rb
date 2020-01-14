# frozen_string_literal: true

# == Schema Information
#
# Table name: activation_calls
#
#  id           :bigint(8)        not null, primary key
#  gift_card_id :integer
#  sid          :string(255)
#  transcript   :text(16777215)
#  audio_url    :string(255)
#  call_type    :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  call_status  :string(255)      default("created")
#  token        :string(255)
#

require "faker"

FactoryBot.define do
  factory :activation_call do
    gift_card
    sid { "CA#{SecureRandom.hex(10)}" }
    transcript { Faker::Lorem.paragraph }
    audio_url { "#{Faker::Internet.url}.mp3" }
    call_type { ActivationCall::CALL_TYPE_ACTIVATE }
    call_status { "created" }

    trait :activate do
      call_type { ActivationCall::CALL_TYPE_ACTIVATE }
    end

    trait :check do
      call_type { ActivationCall::CALL_TYPE_CHECK }
    end

    trait :started do
      call_status { ActivationCall::CALL_STATUS_STARTED }
    end
  end
end
