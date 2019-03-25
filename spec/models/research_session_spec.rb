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

require 'rails_helper'

xdescribe ResearchSession do
  it { is_expected.to validate_presence_of(:people_ids) }
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:slot_length) }
  it { is_expected.to validate_presence_of(:date) }
  it { is_expected.to validate_presence_of(:start_time) }
  it { is_expected.to validate_presence_of(:end_time) }

  describe '#save' do
    let(:people) { FactoryBot.create_list(:person, 2) }
    let(:user) { FactoryBot.create(:user) }
    let(:valid_args) do
      {
        people_ids: people.map(&:id).join(','),
        description: 'lorem',
        slot_length: '45 mins',
        date: '03/20/2016',
        start_time: '15:00',
        end_time: '16:30',
        title: 'title',
        user_id: user.id
      }
    end

    describe 'when valid' do
      subject { described_class.new(valid_args) }

      it 'creates a new event' do
        # expect { subject.save }.to change { V2::Event.count }.from(0).to(1)
      end

      it 'creates new time slots' do
        # expect { subject.save }.to change { V2::TimeSlot.count }.from(0).to(2)
      end

      it 'finds the invitees and associates the to the event' do
        subject.save
        expect(subject.invitees.collect(&:id).sort).to eql people.collect(&:id).sort
      end

      it 'associates event to its creator' do
        subject.save
        expect(subject.event.user_id).to eq(user.id)
      end
    end

    describe 'when bogus ids are present' do
      subject { described_class.new(valid_args.merge(people_ids: '5343,123412,32423')) }

      it 'validates email addresses belong to registered people' do
        subject.save
        expect(subject.errors.messages[:people_ids]).to eql ['One or more of the people are not registered']
      end
    end

    describe 'with missing data' do
      it 'returns false' do
        expect(subject.save).to eql false
      end
    end
  end
end
