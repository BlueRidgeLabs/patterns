# frozen_string_literal: true

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

require "rails_helper"

describe ResearchSession do
  describe "#save" do
    let(:people) { FactoryBot.create_list(:person, 2) }
    let(:user) { FactoryBot.create(:user) }
    let(:valid_args) do
      {
        description: "lorem",
        sms_description: "foobar",
        duration: 60,
        start_datetime: DateTime.now,
        title: "title",
        user_id: user.id
      }
    end

    let(:invalid_args) do
      {
        description: nil,
        sms_description: nil,
        duration: -10,
        start_datetime: DateTime.now,
        title: "title",
        user_id: user.id
      }
    end

    describe "when invalid" do
      subject { described_class.new(invalid_args) }
      it "should be invalid" do
        expect(subject.valid?).to eql false
        expect(subject.save).to eql false

        expect(subject.errors.messages[:description]).to eql ["can't be blank"]
        expect(subject.errors.messages[:duration]).to eql ["must be greater than or equal to 0"]
      end
    end

    describe "when valid" do
      subject { described_class.new(valid_args) }

      it "creates a new event" do
        expect { subject.save }.to change { ResearchSession.all.size }.from(0).to(1)
      end

      it "finds the invitees and associates the to the event" do
        subject.save
        people.each do |p|
          Invitation.create(research_session_id: subject.id,
                            person_id: p.id)
        end
        subject.reload
        expect(subject.invitations.collect(&:person_id).sort).to eql people.collect(&:id).sort
      end

      it "associates event to its creator" do
        subject.save
        expect(subject.user_id).to eq(user.id)
      end
    end

    describe "with missing data" do
      it "returns false" do
        expect(subject.save).to eql false
      end
    end

    describe "future, fully hydrated research session" do
      after(:all) do
        Timecop.return
      end

      let(:admin) { FactoryBot.create(:user, :admin) }
      let(:rs) { FactoryBot.create(:research_session, user: admin) }
      let(:invitation) do
        FactoryBot.create(:invitation,
                          research_session: rs)
      end

      let(:reward) do
        FactoryBot.create(:reward,
                          :gift_card,
                          amount: 25,
                          giftable: invitation,
                          user: admin)
      end

      it "should have a rewarded person" do
        rs.reload
        expect(reward.amount.to_s).to eq("25.00")
        expect(rs.rewards.size).to eq(1)
        expect(admin.rewards_total.to_s).to eq("25.00")
        expect(invitation.person.rewards_total.to_s).to eq("25.00")
        expect(invitation.person.rewards_count).to eq(1)
      end

      it "can add a digital gift as a reward" do
        reward.save
        rs.reload
        Timecop.travel(rs.start_datetime + 5.days)
        invitation.attend!
        dg = FactoryBot.create(:reward,
                               :digital_gift,
                               giftable: invitation,
                               user: admin)
        dg.save
        invitation.reload
        expect(invitation.rewards.size).to eq(2)
        expect(dg.giftable).to eq(invitation)
      end
    end
  end
end
