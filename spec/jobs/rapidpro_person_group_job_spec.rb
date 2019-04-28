require "rails_helper"

RSpec.describe RapidproPersonGroupJob, :type => :job do
  let(:sut) { RapidproPersonGroupJob }
  let(:people) { FactoryBot.create_list(:person, 110) }
  let(:rapidpro_uuid) { "fake_uuid" }
  let(:cart) { FactoryBot.create(:cart, rapidpro_sync: true, rapidpro_uuid: rapidpro_uuid) }

  def perform_job(action)
    sut.new.perform(people.pluck(:id), cart.id, action)
  end

  before do
    allow(HTTParty).to receive(:post)
  end

  context "rapidpro sync is false for cart" do
    before { cart.update(rapidpro_sync: false) }

    it "doesn't do a damn thing" do
      perform_job("add")
      expect(HTTParty).not_to receive(:post)
    end
  end

  context "rapidpro uuid for cart is nil" do
    before { cart.update(rapidpro_uuid: nil) }

    it "raises error" do
      expect { perform_job("add") }.to raise_error(RuntimeError)
    end
  end

  context "action invalid" do
    it "raises error" do
      expect { perform_job("covfefe") }.to raise_error(RuntimeError)
    end
  end

  context "rapidpro returns status 429" do
    it "enqueues job to be re-run later, with remaining people" do
    end
  end

  context "valid action, rapidpro info correct, and rate-limit not exceeded" do
    context "action is 'add'" do
      it "adds people to rapidpro" do
      end
    end

    context "action is 'remove'" do
      it "removes people from rapidpro" do
      end
    end
  end
end
