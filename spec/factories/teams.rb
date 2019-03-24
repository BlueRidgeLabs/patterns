require 'faker'

FactoryBot.define do
  factory :team do
    name { Faker::Name.name }
    finance_code "BRL"
    description { Faker::Lorem.sentence }
  end
end
