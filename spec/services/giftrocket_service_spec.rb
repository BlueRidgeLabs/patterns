require "rails_helper"

RSpec.describe GiftrocketService do
  let(:sut) { GiftrocketService }

  describe "#create_order!" do
    let(:person) { FactoryBot.create(:person) }
    let(:digital_gift) { FactoryBot.create(:digital_gift, amount_cents: 40_00, person: person) }
    let(:gr_gift_id) { 'covfefe_gift_id' }
    let(:gr_order_id) { 'covfefe_order_id' }
    let(:gr_funding_source_id) { 'covfefe_fs_id' }
    let(:gr_recipient_link) { 'https://covfefe.com' }
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
      allow(mock_balance_funding_source).to receive(:method).and_return('balance')
      allow(mock_balance_funding_source).to receive(:id).and_return(gr_funding_source_id)
      mock_funding_sources = [mock_balance_funding_source]
      allow(Giftrocket::FundingSource).to receive(:list).and_return(mock_funding_sources)
    end

    it "creates a giftrocket order and returns params to be persisted on digital gift" do
      expected_external_id = {
        person_id: digital_gift.person_id,
        giftable_id: digital_gift.giftable_id,
        giftable_type: digital_gift.giftable_type
      }.to_json
      expect(Giftrocket::Order).to receive(:create!).with({
        external_id: expected_external_id,
        funding_source_id: gr_funding_source_id,
        campaign_id: ENV['GIFTROCKET_HIGH_CAMPAIGN'],
        gifts: [
          amount: digital_gift.amount.to_s,
          recipient: {
            name: person.full_name,
            delivery_method: 'LINK'
          }
        ]
      }).and_return(mock_order)
      result = sut.create_order!(digital_gift)
      expect(result).to eq({
        external_id: expected_external_id,
        funding_source_id: gr_funding_source_id,
        campaign_id: ENV['GIFTROCKET_HIGH_CAMPAIGN'],
        fee: gr_fee,
        order_id: gr_order_id,
        gift_id: gr_gift_id,
        link: gr_recipient_link,
        order_details: Base64.encode64(Marshal.dump(mock_order))
      })
    end
  end
end
