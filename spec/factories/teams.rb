# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id           :bigint(8)        not null, primary key
#  name         :string(255)
#  finance_code :string(255)
#  description  :text(16777215)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require "faker"

FactoryBot.define do
  factory :team do
    name { Faker::Name.name }
    finance_code { Team::FINANCE_CODES.sample }
    description { Faker::Lorem.sentence }
  end
end
