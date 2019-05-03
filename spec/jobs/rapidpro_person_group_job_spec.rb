require "rails_helper"

RSpec.describe RapidproPersonGroupJob, :type => :job do
  let(:sut) { RapidproPersonGroupJob }
  let(:people) do
    _p = FactoryBot.create_list(:person, 110, :rapidpro_syncable)
    _p.sort_by(&:id)
  end
  let(:cart) { FactoryBot.create(:cart, rapidpro_sync: true, rapidpro_uuid: SecureRandom.uuid) }

  def perform_job(action)
    sut.new.perform(people.map(&:id), cart.id, action)
  end

  context "rapidpro sync is false for cart" do
    before { cart.update(rapidpro_sync: false) }

    it "doesn't do a damn thing" do
      expect(HTTParty).not_to receive(:post)
      perform_job("add")
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
      rapidpro_409_res = Hashie::Mash.new({ code: 429, headers: { 'retry-after': 100 } })
      action = "add"
      last_100 = people.last(100)
      first_10 = people.first(10)
      request_url = "https://rapidpro.brl.nyc/api/v2/contact_actions.json"
      request_headers = {
        'Authorization' => "Token #{ENV['RAPIDPRO_TOKEN']}",
        'Content-Type'  => 'application/json'
      }
      request_body = {
        action: action,
        contacts: last_100.map(&:rapidpro_uuid),
        group: cart.rapidpro_uuid
      }

      expect(HTTParty).to receive(:post).once.with(request_url, headers: request_headers, body: request_body.to_json).and_return(rapidpro_409_res)
      expect_any_instance_of(sut).to receive(:retry_later).with(first_10.map(&:id), 105)
      perform_job(action)
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
