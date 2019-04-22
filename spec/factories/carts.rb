# frozen_string_literal: true

# == Schema Information
#
# Table name: carts
#
#  id            :integer          not null, primary key
#  name          :string(255)      default("default")
#  user_id       :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  description   :text(16777215)
#  people_count  :integer          default(0)
#  rapidpro_uuid :string(255)
#  rapidpro_sync :boolean          default(FALSE)
#

require 'faker'

FactoryBot.define do
  factory :cart do
    user
    name { Faker::Lorem.words(2).join(" ") }
    description { Faker::Lorem.sentence }
  end
end
