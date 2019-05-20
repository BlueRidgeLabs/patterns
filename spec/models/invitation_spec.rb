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
  
  describe 'creating' do
    let(:invitation) {FactoryBot.create(:invitation)}
    let(:research_session) { invitation.research_session }
    let(:admin) {FactoryBot.create(:user,:admin)}
    let(:user) { invitation.user }
    let(:person) { invitation.person }
    let(:other_person) { FactoryBot.create(:person) }
    let(:research_session_2) { FactoryBot.create(:research_session) }
    let(:now) { Time.current }
    let(:gift_card) { FactoryBot.create(:gift_card, :active, user: user) }
    
    after(:all) do
      Timecop.return
    end

    it 'should be valid' do
      expect(research_session).to be_valid
      expect(research_session.end_datetime.class).to be(ActiveSupport::TimeWithZone)
      expect(person.invitations.first).to eq(invitation)
    end
    
    it 'should move through states' do
      expect(invitation.aasm_state).to eq('created')
      expect(invitation.can_miss?).to eq(false)
      expect{ invitation.invite }.to change { invitation.aasm_state }.from('created').to('invited')
      expect{ invitation.remind }.to change { invitation.aasm_state }.from('invited').to('reminded')
      expect(invitation.permitted_states).to_not include('created','invited')
    end

    it 'should have correct time management' do
      Timecop.travel(invitation.start_datetime + 1.year)
      expect(invitation.can_miss?).to eq(true)
      expect(invitation.in_past?).to eq(true)

      Timecop.travel(invitation.start_datetime - 1.year)
      expect(invitation.in_future?).to eq(true)
      
    end

    it 'has people and users' do
      expect(invitation.owner_or_invitee?(person)).to eq(true)
      expect(invitation.owner_or_invitee?(research_session.user)).to eq(true)
      expect(invitation.owner_or_invitee?(admin)).to eq(false)
    end

    it 'should show up in scopes' do
      Timecop.travel(invitation.start_datetime - 2.days)
      expect(Invitation.upcoming).to include(invitation)
    end
    
    it 'should be able to be rewarded' do
      
      reward = Reward.create(rewardable_type: gift_card.class,
                           rewardable_id: gift_card.id,
                           amount: gift_card.amount,
                           reason: 4, #interview
                           user_id: user.id,
                           person_id: person.id,
                           giftable_type: 'Invitation',
                           giftable_id: invitation.id,
                           finance_code: user&.team&.finance_code,
                           team: user&.team,
                           created_by: user.id)

      invitation.reload
      expect(invitation.can_miss?).to eq(false)
      expect(invitation.rewards.empty?).to eq(false)
      expect(invitation.rewards.first).to eq(reward)
      
      inv_count = Invitation.all.size
      expect { invitation.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      expect(Invitation.all.size).to eq(inv_count)

      reward.destroy
      invitation.reload

      expect { invitation.destroy }.to change {Invitation.all.size}.by(-1)
    end

    it 'should not miss invitations in the future' do
      Timecop.travel(now - 1.year)
      expect {invitation.miss }.to_not change { invitation.aasm_state }
      Timecop.travel(now + 1.year)
      expect {invitation.miss }.to change { invitation.aasm_state }.from('created').to('missed')
    end
    
    it 'should not attend invitations in the future' do
      Timecop.travel(now - 1.year)
      expect {invitation.attend }.to raise_error(AASM::InvalidTransition)
    end

    it 'should attend invitations in the past' do
      Timecop.travel(invitation.start_datetime + 1.hour)
      expect { invitation.attend }.to change { invitation.aasm_state }.from('created').to('attended')
    end
    
    it 'should guard against actions in the past' do
      Timecop.travel(invitation.start_datetime + 1.year)
      expect { invitation.invite }.to raise_error(AASM::InvalidTransition)
      expect { invitation.remind }.to raise_error(AASM::InvalidTransition)
      expect { invitation.confirm }.to raise_error(AASM::InvalidTransition)
      expect { invitation.cancel }.to raise_error(AASM::InvalidTransition)
    end

    it 'should not destroy attended invitations' do
      Timecop.travel(invitation.start_datetime + 2.hours)
      expect(invitation.in_past?).to eq(true)
      invitation.attend
      expect { invitation.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end

    it 'should not destroy missed invitations' do
      Timecop.travel(invitation.start_datetime + 1.week)
      invitation.miss
      expect { invitation.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end
  end

end

