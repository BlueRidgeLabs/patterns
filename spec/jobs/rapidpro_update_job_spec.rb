# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RapidproUpdateJob, type: :job do
  let(:sut) { described_class }
  let(:person) { FactoryBot.create(:person, :rapidpro_syncable) }
  let(:cart) {FactoryBot.create(:cart, :rapidpro) }
  let(:action) { sut.new.perform(person.id) }
  let(:rapidpro_req_headers) { { 'Authorization' => "Token #{Rails.application.credentials.rapidpro[:token]}", 'Content-Type' => 'application/json' } }
  let(:rapidpro_res) do
    Hashie::Mash.new(
      code: 200
    )
  end

  before { allow(HTTParty).to receive(:post).and_return(rapidpro_res) }

  context 'person not dig' do
    it 'enqueues RapidproDeleteJob' do
      person.update(tag_list: 'not dig')
      expect(RapidproDeleteJob).to receive(:perform_async).with(person.id)
      action
    end
  end

  context 'person not active' do
    it 'enqueues RapidproDeleteJob' do
      person.update(active: false)
      expect(RapidproDeleteJob).to receive(:perform_async).with(person.id)
      action
    end
  end

  context "person doesn't have phone number" do
    it "doesn't do a damn thing" do
      person.update(phone_number: nil)
      expect(HTTParty).not_to receive(:post)
      expect(sut).not_to receive(:perform_in)
      action
    end
  end

  context 'person has rapidpro_uuid' do
    before { person.update(tag_list: 'tag 1, tag 2') }

    context 'person has email' do
      it "adds tel and email to RP URNs, adds tags to RP fields, and adds to group 'DIG'" do
        expect(HTTParty).to receive(:post).with(
          "https://#{Rails.application.credentials.rapidpro[:domain]}/api/v2/contacts.json?uuid=#{person.rapidpro_uuid}",
          headers: rapidpro_req_headers,
          body: {
            name: person.full_name,
            first_name: person.first_name,
            language: RapidproService.language_for_person(person),
            urns: ["tel:#{person.phone_number}", "mailto:#{person.email_address}"],
            groups: ['DIG'],
            fields: {
              tags: 'tag_1 tag_2',
              verified: person.verified
            }
          }.to_json
        )
        action
      end
    end
    
    context "person is in synced cart" do
      before { cart.people << person }
      it "sends all of the synced groups to rapidpro" do
        expect(HTTParty).to receive(:post).with(
          "https://#{Rails.application.credentials.rapidpro[:domain]}/api/v2/contacts.json?uuid=#{person.rapidpro_uuid}",
          headers: rapidpro_req_headers,
          body: {
            name: person.full_name,
            first_name: person.first_name,
            language: RapidproService.language_for_person(person),
            urns: ["tel:#{person.phone_number}","mailto:#{person.email_address}"],
            groups: ['DIG', cart.name],
            fields: {
              tags: 'tag_1 tag_2',
              verified: person.verified
            }
          }.to_json
        )
        action
      end
    end
    
    context "person doesn't have email" do
      it "adds tel to RP URNs, adds tags to RP fields, and adds to group 'DIG'" do
        person.update(email_address: nil)
        expect(HTTParty).to receive(:post).with(
          "https://#{Rails.application.credentials.rapidpro[:domain]}/api/v2/contacts.json?uuid=#{person.rapidpro_uuid}",
          headers: rapidpro_req_headers,
          body: {
            name: person.full_name,
            first_name: person.first_name,
            language: RapidproService.language_for_person(person),
            urns: ["tel:#{person.phone_number}"],
            groups: ['DIG'],
            fields: {
              tags: 'tag_1 tag_2',
              verified: person.verified
            }
          }.to_json
        )
        action
      end
    end
  end

  context "person doesn't have rapidpro_uuid" do
    it 'finds contact on rapidpro through phone #' do
      person.update(rapidpro_uuid: nil)
      expect(HTTParty).to receive(:post).with(
        "https://#{Rails.application.credentials.rapidpro[:domain]}/api/v2/contacts.json?urn=#{CGI.escape("tel:#{person.phone_number}")}",
        headers: rapidpro_req_headers,
        body: {
          name: person.full_name,
          first_name: person.first_name,
          language: RapidproService.language_for_person(person)
        }.to_json
      )
      action
    end
  end

  context 'rapidpro responds with 201' do
    let(:rapidpro_res) do
      Hashie::Mash.new(
        code: 201,
        parsed_response: {
          uuid: 'fakeuuid'
        }
      )
    end

    context 'person has rapidpro_uuid' do
      it 'does nothing' do
        expect(sut).not_to receive(:perform_in)
        action
      end
    end

    context "person doesn't have rapidpro_uuid yet" do
      it 'sets rapidpro_uuid on person' do
        person.update(rapidpro_uuid: nil)
        expect(sut).to receive(:perform_in)
        action
        expect(person.reload.rapidpro_uuid).to eq('fakeuuid')
      end
    end
  end

  context 'rapidpro responds with 429' do
    let(:rapidpro_res) do
      Hashie::Mash.new(
        code: 429,
        headers: {
          'retry-after': 100
        }
      )
    end

    it 'enqueues job to be retried' do
      expect(sut).to receive(:perform_in).with(100 + 5, person.id)
      action
    end
  end

  xcontext 'rapidpro responds with 502' do
    let(:rapidpro_res) do
      Hashie::Mash.new(
        code: 502
      )
    end

    it 'enqueues job to be retried' do
      expect(sut).to receive(:perform_in)
    end
  end

  context 'rapidpro responds with 200' do
    let(:rapidpro_res) do
      Hashie::Mash.new(
        code: 200
      )
    end

    it 'does nothing and returns true' do
      expect(sut).not_to receive(:perform_in)
      expect(action).to eq(true)
    end
  end

  context 'rapidpro responds with unknown status' do
    let(:rapidpro_res) do
      Hashie::Mash.new(
        code: 666
      )
    end

    it 'raises error' do
      expect(sut).not_to receive(:perform_in)
      expect { action }.to raise_error(RuntimeError)
    end
  end
end
