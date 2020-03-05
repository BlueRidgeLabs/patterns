# frozen_string_literal: true

require "rails_helper"

RSpec.describe DigitalGiftsController, type: :controller do
  describe "#create" do
    let(:person) { FactoryBot.create(:person) }
    let(:user) { FactoryBot.create(:user) }
    let(:invitation) { FactoryBot.create(:invitation) }
    let(:notes) { "Covfefe Notes" }
    let(:reason) { "focus_group" }
    let(:amount) { 20 }
    let(:params) { {
      person_id: person.id,
      user_id: user.id,
      notes: notes,
      reason: reason,
      amount: amount,
      giftable_type: "Invitation",
      giftable_id: invitation.id
    }}
    before { sign_in user }

    describe "error handling" do
      it "errors if giftable is nil" do
        params[:giftable_id] = 20000000000
        post :create, params: params, xhr: true
        expect(flash[:error]).to eq("No giftable object present")
        expect(DigitalGift.count).to eq(0)
        expect(Reward.count).to eq(0)
      end

      it 'errors if giftable is Invitation that is not marked as "attended"' do
        allow(invitation).to receive(:attended?).and_return(false)
        post :create, params: params, xhr: true
        expect(flash[:error]).to eq("#{invitation.person.full_name} isn't marked as 'attended'.")
        expect(DigitalGift.count).to eq(0)
        expect(Reward.count).to eq(0)
      end

      it "errors if giftable is Invitation that already has a digitable gift" do
        reward = FactoryBot.create(:reward, :digital_gift)
        invitation.update(aasm_state: "attended")
        expect(DigitalGift.count).to eq(1)
        expect(Reward.count).to eq(1)
        allow(invitation).to receive(:attended?).and_return(true)
        invitation.rewards << reward
        post :create, params: params, xhr: true
        expect(flash[:error]).to eq("#{invitation.person.full_name} Already has a digital gift")
        expect(DigitalGift.count).to eq(1)
        expect(Reward.count).to eq(1)
      end

      it "errors if digital gift not allowed to be ordered" do
        allow(DigitalGiftService).to receive(:validate_params)
        post :create, params: params, xhr: true
        expect(DigitalGift.count).to eq(0)
        expect(Reward.count).to eq(0)
        expect(flash[:error]).to eq("Insufficient budget to order from Giftrocket")
      end
    end

    # TODO: (EL) write this test before using DigitalGiftService.create in dg controller
    xit "creates an associated gift and reward" do
    end
  end
end
