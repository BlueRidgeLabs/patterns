# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                      :integer          not null, primary key
#  email                   :string(255)      default(""), not null
#  encrypted_password      :string(255)      default(""), not null
#  reset_password_token    :string(255)
#  reset_password_sent_at  :datetime
#  remember_created_at     :datetime
#  sign_in_count           :integer          default(0)
#  current_sign_in_at      :datetime
#  last_sign_in_at         :datetime
#  current_sign_in_ip      :string(255)
#  last_sign_in_ip         :string(255)
#  password_salt           :string(255)
#  invitation_token        :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  approved                :boolean          default(FALSE), not null
#  name                    :string(255)
#  token                   :string(255)
#  phone_number            :string(255)
#  new_person_notification :boolean          default(FALSE)
#  team_id                 :bigint(8)
#  invitation_created_at   :datetime
#  invitation_sent_at      :datetime
#  invitation_accepted_at  :datetime
#  invitation_limit        :integer
#  invited_by_type         :string(255)
#  invited_by_id           :bigint(8)
#  invitations_count       :integer          default(0)
#

require 'faker'

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { '234klj242lk3j' }
    password_confirmation { '234klj242lk3j' }
    approved { true }
    name { Faker::Name.name }
    phone_number { Faker::PhoneNumber.cell_phone }
    team
    new_person_notification { false }

    trait :admin do
      new_person_notification { true }
    end

    trait :unapproved do
      approved { false }
    end
  end
end
