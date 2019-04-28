require "rails_helper"

RSpec.describe RapidproPersonGroupJob, :type => :job do
  let(:sut) { RapidproPersonGroupJob }

  before do
    allow(HTTParty).to receive(:post)
  end

  context "rapidpro sync is false for cart" do
    it "doesn't do a damn thing" do
    end
  end

  context "rapidpro uuid for cart is nil" do
    it "raises error" do
    end
  end

  context "action invalid" do
    it "raises error" do
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
