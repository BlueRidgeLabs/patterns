require "rails_helper"

RSpec.describe RapidproGroupJob, :type => :job do
  let(:sut) { RapidproGroupJob }
  let(:rapidpro_base_uri) { 'https://rapidpro.brl.nyc/api/v2/' }
  let(:rapidpro_headers) { {
    'Authorization' => "Token #{ENV['RAPIDPRO_TOKEN']}",
    'Content-Type'  => 'application/json'
  } }

  let(:cart) { FactoryBot.create(:cart, rapidpro_uuid: SecureRandom.uuid) }

  xcontext "action is 'create'" do
    context "rapidpro_uuid present, but group doesn't actually exist" do
    end

    context "rate limit hit" do
    end

    context "rate limit not hit" do
    end
  end

  context "action is 'delete'" do
    context "rapidpro_uuid not present" do
      before { cart.update(rapidpro_uuid: nil) }

      it "doesn't do a damn thing" do
        expect(HTTParty).not_to receive(:delete)
        expect(sut).not_to receive(:perform_in)
        sut.new.perform(cart.id, 'delete')
      end
    end

    context "unknown status returned from rapidpro" do
      it "raises error" do
        rapidpro_ok_res = Hashie::Mash.new({ code: 666 })
        rapidpro_uri = "#{rapidpro_base_uri}groups.json?uuid=#{cart.rapidpro_uuid}"
        expect(HTTParty).to receive(:delete).with(rapidpro_uri, headers: rapidpro_headers).and_return(rapidpro_ok_res)
        expect(sut).not_to receive(:perform_in)
        expect { sut.new.perform(cart.id, 'delete') }.to raise_error(RuntimeError)
      end
    end

    context "rate limit hit" do
      it "re-queues job" do
        retry_delay = 100
        rapidpro_429_res = Hashie::Mash.new({ code: 429, headers: { 'retry-after' => retry_delay } })
        rapidpro_uri = "#{rapidpro_base_uri}groups.json?uuid=#{cart.rapidpro_uuid}"
        expect(HTTParty).to receive(:delete).with(rapidpro_uri, headers: rapidpro_headers).and_return(rapidpro_429_res)
        expect(sut).to receive(:perform_in).with(retry_delay + 5, cart.id, 'delete')
        sut.new.perform(cart.id, 'delete')
      end
    end

    context "rate limit not hit" do
      it "does not requeue job" do
        rapidpro_ok_res = Hashie::Mash.new({ code: 204 })
        rapidpro_uri = "#{rapidpro_base_uri}groups.json?uuid=#{cart.rapidpro_uuid}"
        expect(HTTParty).to receive(:delete).with(rapidpro_uri, headers: rapidpro_headers).and_return(rapidpro_ok_res)
        expect(sut).not_to receive(:perform_in)
        sut.new.perform(cart.id, 'delete')
      end
    end
  end

  xdescribe "helper methods" do
    describe "#find_group" do
    end
  end
end
