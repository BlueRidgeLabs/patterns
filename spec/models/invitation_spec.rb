# == Schema Information
#
# Table name: invitations
#
#  id                  :integer          not null, primary key
#  person_id           :integer
#  created_at          :datetime
#  updated_at          :datetime
#  research_session_id :integer
#  aasm_state          :string(255)
#

require 'rails_helper'

describe Invitation do
  # it { is_expected.to validate_presence_of(:person) }
  # it { is_expected.to validate_presence_of(:user) }
  # it { is_expected.to validate_presence_of(:time_slot) }
  # it { is_expected.to validate_presence_of(:event) }
  # it { is_expected.to validate_presence_of(:event_invitation) }
  # it { is_expected.to validate_uniqueness_of(:time_slot_id) }
  subject { described_class }

  describe 'when different users, same person' do
    let(:research_session) { FactoryBot.create(:research_session) }
    let(:person) { event_invitation.invitees.first }
    let(:research_session_2) { FactoryBot.create(:research_session) }

    it 'should not alow a person to be double booked' do
      valid_args_1 = build_valid_args_from_event_invitation(research_session)
      #research_session_2.people << person

      valid_args_2 = build_valid_args_from_event_invitation(event_invitation_2)
      valid_args_2[:person] = person

      reservation_1 = subject.new(valid_args_1)
      expect(reservation_1).to be_valid
      reservation_1.save
      reservation_2 = subject.new(valid_args_2)
      expect(reservation_2).not_to be_valid
    end
  end

  describe 'same user, different people' do
    let(:research_session) { FactoryBot.create(:research_session) }
    let(:research_session_2) { FactoryBot.create(:research_session, user: research_session.user) }

    it 'should not allow a user to be double booked' do
      valid_args_1 = build_valid_args_from_event_invitation(event_invitation)
      valid_args_2 = build_valid_args_from_event_invitation(event_invitation_2)

      reservation_1 = subject.new(valid_args_1)
      expect(reservation_1).to be_valid
      reservation_1.save
      reservation_2 = subject.new(valid_args_2)
      expect(reservation_2).not_to be_valid
    end
  end
end

