# frozen_string_literal: true

# == Schema Information
#
# Table name: people
#
#  id                               :integer          not null, primary key
#  first_name                       :string(255)
#  last_name                        :string(255)
#  email_address                    :string(255)
#  address_1                        :string(255)
#  address_2                        :string(255)
#  city                             :string(255)
#  state                            :string(255)
#  postal_code                      :string(255)
#  geography_id                     :integer
#  primary_device_id                :integer
#  primary_device_description       :string(255)
#  secondary_device_id              :integer
#  secondary_device_description     :string(255)
#  primary_connection_id            :integer
#  primary_connection_description   :string(255)
#  phone_number                     :string(255)
#  participation_type               :string(255)
#  created_at                       :datetime
#  updated_at                       :datetime
#  signup_ip                        :string(255)
#  signup_at                        :datetime
#  voted                            :string(255)
#  called_311                       :string(255)
#  secondary_connection_id          :integer
#  secondary_connection_description :string(255)
#  verified                         :string(255)
#  preferred_contact_method         :string(255)
#  token                            :string(255)
#  active                           :boolean          default(TRUE)
#  deactivated_at                   :datetime
#  deactivated_method               :string(255)
#  neighborhood                     :string(255)
#  referred_by                      :string(255)
#  low_income                       :boolean
#  rapidpro_uuid                    :string(255)
#  landline                         :string(255)
#  created_by                       :integer
#  screening_status                 :string(255)      default("new")
#  phone_confirmed                  :boolean          default(FALSE)
#  email_confirmed                  :boolean          default(FALSE)
#  confirmation_sent                :boolean          default(FALSE)
#  welcome_sent                     :boolean          default(FALSE)
#  participation_level              :string(255)      default("new")
#  locale                           :string(255)      default("en")
#  cached_tag_list                  :text(65535)
#

require 'faker'

# this is unused....
devices = Patterns::Application.config.device_mappings
connections = Patterns::Application.config.connection_mappings

FactoryBot.define do
  factory :person do
    first_name        { Faker::Name.first_name }
    last_name         { Faker::Name.last_name }
    email_address     { Faker::Internet.email }
    phone_number      { Faker::PhoneNumber.cell_phone }
    address_1         { Faker::Address.street_address }
    address_2         { Faker::Address.secondary_address }
    city              { Faker::Address.city }
    state             { Faker::Address.state }
    postal_code       { 11_222 }
    low_income        true
    signup_at         Time.current
    primary_device_id devices[:desktop]
    primary_device_description 'crawling'
    token { Faker::Alphanumeric.alpha(number: 10) }
    secondary_device_id devices[:tablet]
    secondary_device_description 'nice'
    verified 'Verified' # means we can get in touch
    primary_connection_id connections[:phone]
    primary_connection_description 'so so'
    secondary_connection_id connections[:public_wifi]
    secondary_connection_description 'worse'
    trait :not_dig do
      # tagged with 'not dig' stops a whole bunch of things from happening
      after(:create) { |person| person.update_attributes(tag_list: 'not dig') }
    end

    trait :rapidpro_syncable do
      rapidpro_uuid { SecureRandom.uuid }
    end

    trait :consent_form_attached do
      after(:build) do |person|
        person.consent_form.attach(io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'brl_consent_form_2020.pdf')), filename: 'brl_consent_form_2020.pdf', content_type: 'application/pdf')
      end
    end
  end
end
