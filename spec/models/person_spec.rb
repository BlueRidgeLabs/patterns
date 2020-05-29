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

require 'rails_helper'

describe Person do
  subject { FactoryBot.build(:person) }

  let(:now) { DateTime.current }
  let(:more_than_a_year_ago) { now - 1.year - 1.day }
  let(:less_than_a_year_ago) { now - 1.year + 1.day }
  let(:more_than_six_months_ago) { now - 6.months - 1.day }
  let(:less_than_six_months_ago) { now - 6.months + 1.day }

  describe 'validations' do
    it 'validates uniqueness of phone_number' do
      expect(subject).to be_valid
      another_person = FactoryBot.create(:person)
      subject.phone_number = another_person.phone_number
      expect(subject).not_to be_valid
    end

    it 'requires either a phone number or an email to be present' do
      expect(subject).to be_valid
      subject.email_address = ''
      expect(subject).to be_valid
      subject.phone_number = ''

      expect(subject).not_to be_valid
      subject.email_address = 'jessica@jones.com'
      expect(subject).to be_valid
    end
  end

  describe 'class methods' do
    describe '#update_all_participation_levels' do
      let!(:approved_admin_user) { FactoryBot.create(:user, :admin) }
      let!(:unapproved_admin_user) { FactoryBot.create(:user, :admin, :unapproved) }
      let!(:approved_non_admin_user) { FactoryBot.create(:user) }
      let!(:unapproved_non_admin_user) { FactoryBot.create(:user, :unapproved) }

      it 'updates the participation level for all active people, and then sends an email to all admin users with results' do
        # `tag_list: "brl special ambassador", participation_level: "new"`
        # ensures that `update_participation_level` returns a non-nil value,
        # which we need in order to test that this method works
        active_person = FactoryBot.create(:person, active: true, tag_list: 'brl special ambassador', participation_level: 'new')
        FactoryBot.create(:person, active: false, tag_list: 'brl special ambassador', participation_level: 'new')

        mail_double = double(:mail)
        # expect(AdminMailer).to receive(:participation_level_change).with(
        #   results: [{:pid=>active_person.id, :old=>"new", :new=>"ambassador"}],
        #   to: approved_admin_user.email
        #  ).and_return(mail_double)

        [unapproved_admin_user, approved_non_admin_user, unapproved_non_admin_user].each do |user|
          expect(AdminMailer).not_to receive(:participation_level_change).with(
            results: [{ pid: active_person.id, old: 'new', new: 'ambassador' }],
            to: user.email
          )
        end

        # expect(mail_double).to receive(:deliver_later)
        described_class.update_all_participation_levels
      end

      context 'no results' do
        it "doesn't send an email" do
          FactoryBot.create(:person, active: true, participation_level: 'new')
          FactoryBot.create(:person, active: false, participation_level: 'new')
          # results should be [nil, nil] before compacted to []
          expect(AdminMailer).not_to receive(:participation_level_change)
          described_class.update_all_participation_levels
        end
      end
    end

    describe '#locale_name_to_locale(locale_name)' do
      it 'works' do
        expect(described_class.locale_name_to_locale('english')).to eq('en')
        expect(described_class.locale_name_to_locale('ENgliSh')).to eq('en')
        expect(described_class.locale_name_to_locale('spanish')).to eq('es')
        expect(described_class.locale_name_to_locale('spanisH')).to eq('es')
        expect(described_class.locale_name_to_locale('chinese')).to eq('zh')
        expect(described_class.locale_name_to_locale('covfefe')).to be_nil
      end
    end
  end

  describe 'instance methods' do
    describe '#update_participation_level' do
      let(:person) { FactoryBot.create(:person) }
      let(:action) { person.update_participation_level }

      context 'not dig' do
        before { person.update(tag_list: 'not dig') }

        it 'returns nil' do
          expect(action).to be_nil
        end
      end

      context 'participation_level not changed' do
        it 'returns nil and does nothing' do
          old_level = person.participation_level
          expect(person).to receive(:calc_participation_level).and_return(old_level)
          expect(action).to be_nil
          expect(person.reload.participation_level).to eq(old_level)
        end
      end

      context 'participation_level has changed' do
        it 'updates participation_level, updates tag list, updates placement in cart, and returns hash with id, old level, and new level' do
          Person::PARTICIPATION_LEVELS.each do |pl|
            FactoryBot.create(:cart, name: pl)
          end
          new_cart = Cart.find_by(name: Person::PARTICIPATION_LEVEL_NEW)
          ambassador_cart = Cart.find_by(name: Person::PARTICIPATION_LEVEL_AMBASSADOR)

          person.update(tag_list: Person::PARTICIPATION_LEVEL_NEW, participation_level: Person::PARTICIPATION_LEVEL_NEW)

          new_level = Person::PARTICIPATION_LEVEL_AMBASSADOR
          expect(person).to receive(:calc_participation_level).and_return(new_level)

          expect(action).to eq(pid: person.id, old: Person::PARTICIPATION_LEVEL_NEW, new: Person::PARTICIPATION_LEVEL_AMBASSADOR)
          expect(person.reload.participation_level).to eq(Person::PARTICIPATION_LEVEL_AMBASSADOR)
          expect(new_cart.reload.people.find_by(id: person.id)).to be_nil
          expect(ambassador_cart.reload.people.find_by(id: person.id)).to be_truthy
        end
      end
    end

    describe '#calc_participation_level' do
      context 'ambassador_criteria met' do
        let(:person) { FactoryBot.create(:person) }

        it "returns 'ambassador'" do
          allow(person).to receive(:ambassador_criteria).and_return(true)
          allow(person).to receive(:active_criteria).and_return(true)
          allow(person).to receive(:participant_criteria).and_return(true)
          allow(person).to receive(:inactive_criteria).and_return(true)
          expect(person.calc_participation_level).to eq(Person::PARTICIPATION_LEVEL_AMBASSADOR)
        end
      end

      context 'active_criteria met, but ambassador_criteria not met' do
        let(:person) { FactoryBot.create(:person) }

        it "returns 'active'" do
          allow(person).to receive(:ambassador_criteria).and_return(false)
          allow(person).to receive(:active_criteria).and_return(true)
          allow(person).to receive(:participant_criteria).and_return(true)
          allow(person).to receive(:inactive_criteria).and_return(true)
          expect(person.calc_participation_level).to eq(Person::PARTICIPATION_LEVEL_ACTIVE)
        end
      end

      context 'participant_criteria met, but ambassador_criteria and active_criteria not met' do
        let(:person) { FactoryBot.create(:person) }

        it "returns 'participant'" do
          allow(person).to receive(:ambassador_criteria).and_return(false)
          allow(person).to receive(:active_criteria).and_return(false)
          allow(person).to receive(:participant_criteria).and_return(true)
          allow(person).to receive(:inactive_criteria).and_return(true)
          expect(person.calc_participation_level).to eq(Person::PARTICIPATION_LEVEL_PARTICIPANT)
        end
      end

      context 'inactive_criteria met, but ambassador_criteria, participant_criteria, and active_criteria not met' do
        let(:person) { FactoryBot.create(:person) }

        it "returns 'inactive'" do
          allow(person).to receive(:ambassador_criteria).and_return(false)
          allow(person).to receive(:active_criteria).and_return(false)
          allow(person).to receive(:participant_criteria).and_return(false)
          allow(person).to receive(:inactive_criteria).and_return(true)
          expect(person.calc_participation_level).to eq(Person::PARTICIPATION_LEVEL_INACTIVE)
        end
      end

      context 'inactive_criteria, ambassador_criteria, participant_criteria, and active_criteria not met' do
        let(:person) { FactoryBot.create(:person) }

        it "returns 'new'" do
          allow(person).to receive(:ambassador_criteria).and_return(false)
          allow(person).to receive(:active_criteria).and_return(false)
          allow(person).to receive(:participant_criteria).and_return(false)
          allow(person).to receive(:inactive_criteria).and_return(false)
          expect(person.calc_participation_level).to eq(Person::PARTICIPATION_LEVEL_NEW)
        end
      end
    end

    describe '#ambassador_criteria' do
      let(:person) { FactoryBot.create(:person) }

      context "tag list includes 'brl special ambassador'" do
        it 'returns true' do
          expect(person.ambassador_criteria).to eq(false)
          person.update(tag_list: 'brl special ambassador')
          expect(person.ambassador_criteria).to eq(true)
        end
      end

      context 'sessions with 2+ teams in past year, and 3+ sessions ever' do
        it 'returns true' do
          team_1 = FactoryBot.create(:team)
          team_2 = FactoryBot.create(:team)

          expect(person.ambassador_criteria).to eq(false)
          Timecop.freeze(more_than_a_year_ago) do
            FactoryBot.create_list(:reward, 3, :gift_card, person: person)
            person.reload
          end
          Timecop.freeze(less_than_a_year_ago) do
            FactoryBot.create(:reward, :gift_card, person: person, team: team_1)
            person.reload
          end
          expect(person.ambassador_criteria).to eq(false)
          Timecop.freeze(less_than_a_year_ago) do
            FactoryBot.create(:reward, :gift_card, person: person, team: team_1)
            person.reload
          end
          expect(person.ambassador_criteria).to eq(false)
          Timecop.freeze(less_than_a_year_ago) do
            FactoryBot.create(:reward, :gift_card, person: person, team: team_2)
            person.reload
          end
          expect(person.ambassador_criteria).to eq(true)
        end
      end
    end

    describe '#active_criteria' do
      let(:person) { FactoryBot.create(:person) }

      context 'at least one reward in past six months' do
        it 'returns true' do
          Timecop.freeze(more_than_six_months_ago) do
            FactoryBot.create(:reward, :gift_card, person: person)
            person.reload
          end
          expect(person.active_criteria).to eq(false)
          Timecop.freeze(less_than_six_months_ago) do
            FactoryBot.create(:reward, :gift_card, person: person)
            person.reload
          end
          expect(person.active_criteria).to eq(true)
        end
      end
    end

    describe '#participant_criteria' do
      let(:person) { FactoryBot.create(:person) }

      context 'at least one reward in the past year' do
        it 'returns true' do
          Timecop.freeze(more_than_a_year_ago) do
            FactoryBot.create(:reward, :gift_card, person: person)
            person.reload
          end
          expect(person.participant_criteria).to eq(false)
          Timecop.freeze(less_than_a_year_ago) do
            FactoryBot.create(:reward, :gift_card, person: person)
            person.reload
          end
          expect(person.participant_criteria).to eq(true)
        end
      end
    end

    describe '#inactive_criteria' do
      let(:person) { FactoryBot.create(:person) }

      context 'at least one reward, but not in the past year' do
        it 'returns true' do
          Timecop.freeze(more_than_a_year_ago) do
            FactoryBot.create(:reward, :gift_card, person: person)
            person.reload
          end
          expect(person.inactive_criteria).to eq(true)
          Timecop.freeze(less_than_a_year_ago) do
            FactoryBot.create(:reward, :gift_card, person: person)
            person.reload
          end
          expect(person.inactive_criteria).to eq(false)
        end
      end
    end
  end
end
