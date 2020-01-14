# frozen_string_literal: true

require "rails_helper"

RSpec.describe RapidproPersonGroupJob, type: :job do
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
      rapidpro_409_res = Hashie::Mash.new(code: 429, headers: { 'retry-after': 100 })
      action = "add"
      last_100 = people.last(100)
      first_10 = people.first(10)
      request_url = "https://rapidpro.brl.nyc/api/v2/contact_actions.json"
      request_headers = { "Authorization" => "Token #{ENV['RAPIDPRO_TOKEN']}", "Content-Type" => "application/json" }
      request_body = { action: action, contacts: last_100.map(&:rapidpro_uuid), group: cart.rapidpro_uuid }

      expect(HTTParty).to receive(:post).once.with(request_url, headers: request_headers, body: request_body.to_json).and_return(rapidpro_409_res)
      expect_any_instance_of(sut).to receive(:retry_later).with(first_10.map(&:id), 105)
      perform_job(action)
    end
  end

  context "valid action, rapidpro info correct, and rate-limit not exceeded" do
    it "skips folx tagged with 'not dig'" do
      dig_people = FactoryBot.create_list(:person, 10, :rapidpro_syncable).to_a.sort_by(&:id)
      not_dig_people = FactoryBot.create_list(:person, 10, :rapidpro_syncable, :not_dig).to_a.sort_by(&:id)
      all_people = (dig_people + not_dig_people).sort_by(&:id)

      rapidpro_ok_res = Hashie::Mash.new(code: 200)
      action = "add"
      request_url = "https://rapidpro.brl.nyc/api/v2/contact_actions.json"
      request_headers = { "Authorization" => "Token #{ENV['RAPIDPRO_TOKEN']}", "Content-Type" => "application/json" }
      request_body = { action: action, contacts: dig_people .map(&:rapidpro_uuid), group: cart.rapidpro_uuid }

      expect(HTTParty).to receive(:post).once.with(request_url, headers: request_headers, body: request_body.to_json).and_return(rapidpro_ok_res)
      sut.new.perform(all_people.map(&:id), cart.id, action)
    end

    context "action is 'add'" do
      it "adds people to rapidpro" do
        rapidpro_ok_res = Hashie::Mash.new(code: 200)
        action = "add"
        last_100 = people.last(100)
        first_10 = people.first(10)
        request_url = "https://rapidpro.brl.nyc/api/v2/contact_actions.json"
        request_headers = { "Authorization" => "Token #{ENV['RAPIDPRO_TOKEN']}", "Content-Type" => "application/json" }
        request_1_body = { action: action, contacts: last_100.map(&:rapidpro_uuid), group: cart.rapidpro_uuid }
        request_2_body = { action: action, contacts: first_10.map(&:rapidpro_uuid), group: cart.rapidpro_uuid }

        expect(HTTParty).to receive(:post).once.with(request_url, headers: request_headers, body: request_1_body.to_json).and_return(rapidpro_ok_res)
        expect(HTTParty).to receive(:post).once.with(request_url, headers: request_headers, body: request_2_body.to_json).and_return(rapidpro_ok_res)
        expect_any_instance_of(sut).not_to receive(:retry_later)
        perform_job(action)
      end
    end

    context "action is 'remove'" do
      it "removes people from rapidpro" do
        rapidpro_ok_res = Hashie::Mash.new(code: 200)
        action = "remove"
        last_100 = people.last(100)
        first_10 = people.first(10)
        request_url = "https://rapidpro.brl.nyc/api/v2/contact_actions.json"
        request_headers = { "Authorization" => "Token #{ENV['RAPIDPRO_TOKEN']}", "Content-Type" => "application/json" }
        request_1_body = { action: action, contacts: last_100.map(&:rapidpro_uuid), group: cart.rapidpro_uuid }
        request_2_body = { action: action, contacts: first_10.map(&:rapidpro_uuid), group: cart.rapidpro_uuid }

        expect(HTTParty).to receive(:post).once.with(request_url, headers: request_headers, body: request_1_body.to_json).and_return(rapidpro_ok_res)
        expect(HTTParty).to receive(:post).once.with(request_url, headers: request_headers, body: request_2_body.to_json).and_return(rapidpro_ok_res)
        expect_any_instance_of(sut).not_to receive(:retry_later)
        perform_job(action)
      end
    end
  end
end
