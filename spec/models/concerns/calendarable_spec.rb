# frozen_string_literal: true

require 'rails_helper'

describe Calendarable do
  context 'reservation calendar' do
    let!(:invitation) { FactoryBot.create(:invitation) }
    let!(:person) { invitation.person }
    let!(:research_session) { invitation.research_session }
    let!(:user) { research_session.user }

    it 'can generate an ical event' do
      research_session.reload
      expect(research_session).to respond_to(:to_ics)
      expect(research_session.to_ics.description).to include(research_session.description)
    end

    it 'has  an alarm' do
      ics = research_session.to_ics
      expect(ics.alarms.length).to eq(1)
    end

    it 'returns datetimes' do
      klass = ActiveSupport::TimeWithZone
      expect(research_session.start_datetime.class).to eq(klass)
      expect(invitation.start_datetime.class).to eq(klass)
    end
  end

  context 'research session invitation' do
    let(:invitation) { FactoryBot.create(:invitation) }

    it 'can generate an ical event' do
      expect(invitation).to respond_to(:to_ics)
      expect(invitation.to_ics.description).to include(invitation.description)
    end

    it 'does not have an alarm' do
      expect(invitation.to_ics.alarms.length).to eq(0)
    end
  end
end
