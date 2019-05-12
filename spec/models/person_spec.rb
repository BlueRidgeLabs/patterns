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

require 'rails_helper'

describe Person do
  subject { FactoryBot.build(:person) }

  describe "validations" do
    it 'validates uniqueness of phone_number' do
      expect(subject).to be_valid
      another_person = FactoryBot.create(:person)
      subject.phone_number = another_person.phone_number
      expect(subject).to_not be_valid
    end

    it 'requires either a phone number or an email to be present' do
      expect(subject).to be_valid
      subject.email_address = ''
      expect(subject).to be_valid
      subject.phone_number = ''

      expect(subject).to_not be_valid
      subject.email_address = 'jessica@jones.com'
      expect(subject).to be_valid
    end
  end

  describe "class methods" do
    describe "#update_all_participation_levels" do
      let!(:approved_admin_user) { FactoryBot.create(:user, :admin) }
      let!(:unapproved_admin_user) { FactoryBot.create(:user, :admin, :unapproved) }
      let!(:approved_non_admin_user) { FactoryBot.create(:user) }
      let!(:unapproved_non_admin_user) { FactoryBot.create(:user, :unapproved) }

      it "updates the participation level for all active people, and then sends an email to all admin users with results" do
        # `tag_list: "brl special ambassador", participation_level: "new"`
        # ensures that `update_participation_level` returns a non-nil value,
        # which we need in order to test that this method works
        active_person = FactoryBot.create(:person, active: true, tag_list: "brl special ambassador", participation_level: "new")
        FactoryBot.create(:person, active: false, tag_list: "brl special ambassador", participation_level: "new")

        mail_double = double(:mail)
        expect(AdminMailer).to receive(:participation_level_change).with(
          results: [{:pid=>active_person.id, :old=>"new", :new=>"ambassador"}],
          to: approved_admin_user.email
        ).and_return(mail_double)

        [unapproved_admin_user, approved_non_admin_user, unapproved_non_admin_user].each do |user|
          expect(AdminMailer).not_to receive(:participation_level_change).with(
            results: [{:pid=>active_person.id, :old=>"new", :new=>"ambassador"}],
            to: user.email
          )
        end

        expect(mail_double).to receive(:deliver_later)
        Person.update_all_participation_levels
      end

      context "no results" do
        it "doesn't send an email" do
          FactoryBot.create(:person, active: true, participation_level: "new")
          FactoryBot.create(:person, active: false, participation_level: "new")
          # results should be [nil, nil] before compacted to []
          expect(AdminMailer).not_to receive(:participation_level_change)
          Person.update_all_participation_levels
        end
      end
    end
  end
end
