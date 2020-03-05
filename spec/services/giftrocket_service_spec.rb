# frozen_string_literal: true

require "rails_helper"

RSpec.describe GiftrocketService do
  let(:sut) { GiftrocketService }

  describe "#create_order!" do
    let(:user) { FactoryBot.create(:user) }
    let(:person) { FactoryBot.create(:person) }
    let(:digital_gift) { FactoryBot.create(:digital_gift, amount_cents: GiftrocketService::SMALL_DOLLAR_THRESHOLD * 100 + 1_00, person: person, user: user) }
    let(:reward) { FactoryBot.create(:reward, :digital_gift) }
    let(:gr_gift_id) { "covfefe_gift_id" }
    let(:gr_order_id) { "covfefe_order_id" }
    let(:gr_funding_source_id) { "covfefe_fs_id" }
    let(:gr_recipient_link) { "https://covfefe.com" }
    let(:gr_fee) { 1_00 }
    let(:mock_order) {
      Hashie::Mash.new({
        id: gr_order_id,
        payment: {
          fees: gr_fee
        },
        gifts: [{
          id: gr_gift_id,
          raw: {
            recipient: {
              link: gr_recipient_link
            }
          }
        }]
      })
    }

    before do
      mock_balance_funding_source = double("mock_balance_funding_source")
      allow(mock_balance_funding_source).to receive(:method).and_return("balance")
      allow(mock_balance_funding_source).to receive(:id).and_return(gr_funding_source_id)
      mock_funding_sources = [mock_balance_funding_source]
      allow(Giftrocket::FundingSource).to receive(:list).and_return(mock_funding_sources)
    end

    def assert_order_created(campaign_id: ENV["GIFTROCKET_HIGH_CAMPAIGN"], error_raised: false, user_budget: 1000000.to_money)
      allow(user).to receive(:available_budget).and_return(user_budget)

      if error_raised
        expect { sut.create_order!(digital_gift, reward) }.to raise_error
        return
      end

      expected_external_id = {
        person_id: digital_gift.person_id,
        giftable_id: reward.giftable_id,
        giftable_type: reward.giftable_type
      }.to_json
      expect(Giftrocket::Order).to receive(:create!).with({
        external_id: expected_external_id,
        funding_source_id: gr_funding_source_id,
        campaign_id: campaign_id,
        gifts: [
          amount: digital_gift.amount.to_s,
          recipient: {
            name: person.full_name,
            delivery_method: "LINK"
          }
        ]
      }).and_return(mock_order)
      result = sut.create_order!(digital_gift, reward)
      expect(result).to eq({
        external_id: expected_external_id,
        funding_source_id: gr_funding_source_id,
        campaign_id: campaign_id,
        fee: gr_fee,
        order_id: gr_order_id,
        gift_id: gr_gift_id,
        link: gr_recipient_link,
        order_details: Base64.encode64(Marshal.dump(mock_order))
      })
    end

    it "creates a giftrocket order and returns params to be persisted on digital gift" do
      assert_order_created(campaign_id: ENV["GIFTROCKET_HIGH_CAMPAIGN"])
    end

    context "amount is small dollar amount" do
      it "uses gf low campaign" do
        digital_gift.update(amount_cents: GiftrocketService::SMALL_DOLLAR_THRESHOLD * 100 - 1)
        assert_order_created(campaign_id: ENV["GIFTROCKET_LOW_CAMPAIGN"])
      end
    end

    context "digital gift doesn't have person_id" do
      it "raises error" do
        person.destroy
        digital_gift.reload
        assert_order_created(error_raised: true)
      end
    end

    context "reward doesn't have giftable_id" do
      it "raises error" do
        reward.update(giftable_id: nil)
        assert_order_created(error_raised: true)
      end
    end

    context "reward doesn't have giftable_type" do
      it "raises error" do
        reward.update(giftable_type: nil)
        assert_order_created(error_raised: true)
      end
    end

    context "user's available budget is insufficent" do
      it "raises error" do
        assert_order_created(error_raised: true, user_budget: 0.to_money)
      end
    end
  end
end
