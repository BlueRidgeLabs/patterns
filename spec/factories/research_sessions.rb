# frozen_string_literal: true

# == Schema Information
#
# Table name: research_sessions
#
#  id              :integer          not null, primary key
#  description     :text(65535)
#  buffer          :integer          default(0), not null
#  created_at      :datetime
#  updated_at      :datetime
#  user_id         :integer
#  title           :string(255)
#  start_datetime  :datetime
#  end_datetime    :datetime
#  sms_description :string(255)
#  session_type    :integer          default(1)
#  location        :string(255)
#  duration        :integer          default(60)
#  cached_tag_list :string(255)
#

require 'faker'
FactoryBot.define do
  factory :research_session do
    user
    description { Faker::Lorem.sentence }
    title { Faker::Lorem.sentence }
    start_datetime { DateTime.now + 5.days }
    duration { 60 }
    session_type { 1 }
    location { Faker::Boolean.boolean ? Faker::Address.full_address : Faker::PhoneNumber.phone_number }
  end
end
