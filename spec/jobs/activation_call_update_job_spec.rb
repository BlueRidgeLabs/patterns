# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivationCallUpdateJob, type: :job do
  let(:sut) { ActivationCallUpdateJob }
  let(:action) { sut.perform_async }
  let(:redis_double) { double(:redis) }
  let!(:call_1) { FactoryBot.create(:activation_call, :started) }
  let!(:call_2) { FactoryBot.create(:activation_call) }
  let!(:call_3) { FactoryBot.create(:activation_call) }

  before { allow(Redis).to receive(:current).and_return(redis_double) }

  context 'redis response not nil' do
    before { allow(redis_double).to receive(:get).with('ActivationCallUpdateLock').and_return(nil) }

    it 'does nothing' do
      expect_any_instance_of(ActivationCall).not_to receive(:update_front_end)
      expect_any_instance_of(ActivationCall).not_to receive(:destroy)
      expect(redis_double).not_to receive(:setex)
      action
    end
  end

  xcontext 'redis response is nil' do
    it 'goes through each ongoing call, destroys all with no gift card, handles all failures, updates front end, and updates redis' do
      expect(redis_double).to receive(:setex).with('ActivationCallUpdateLock', 5, true)
      expect(call_1).to receive(:update_front_end)
      expect(call_2).not_to receive(:update_front_end)
      expect(call_3).not_to receive(:update_front_end)
      action
    end
  end
end
