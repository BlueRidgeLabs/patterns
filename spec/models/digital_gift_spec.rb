require 'rails_helper'

describe DigitalGift do
  let(:digital_gift) { FactoryBot.create(:digital_gift) }
  let(:reward) { FactoryBot.create(:reward, :digital_gift) }

  describe "#create_order_on_giftrocket!(reward)" do
    it "creates order, and updates record with resulting adapted params" do
      fake_params = { order_id: 'covfefe_id' }
      expect(GiftrocketService).to receive(:create_order!).with(digital_gift, reward).and_return(fake_params)
      digital_gift.create_order_on_giftrocket!(reward)
      expect(digital_gift.reload.order_id).to eq('covfefe_id')
    end

    context "error raised" do
      it "does not update record" do
        allow(GiftrocketService).to receive(:create_order!).with(digital_gift, reward).and_raise("COVFEFE ERROR")
        expect(digital_gift).not_to receive(:update)
      end
    end
  end
end
