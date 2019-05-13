require "rails_helper"

RSpec.describe RapidproUpdateJob, :type => :job do
  let(:sut) { RapidproUpdateJob }
  let(:person) { FactoryBot.create(:person, :rapidpro_syncable) }
  let(:action) { sut.new.perform(person.id) }
  let(:rapidpro_req_headers) { { 'Authorization' => "Token #{ENV['RAPIDPRO_TOKEN']}", 'Content-Type'  => 'application/json' } }
  let(:rapidpro_res) { Hashie::Mash.new({
    code: 200
  }) }

  before { allow(HTTParty).to receive(:post).and_return(rapidpro_res) }

  context "person not dig" do
    it "enqueues RapidproDeleteJob" do
      person.update(tag_list: "not dig")
      expect(RapidproDeleteJob).to receive(:perform_async).with(person.id)
      action
    end
  end

  context "person not active" do
    it "enqueues RapidproDeleteJob" do
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

  context "person has rapidpro_uuid" do
    before { person.update(tag_list: "tag 1, tag 2") }
    context "person has email" do
      it "adds tel and email to RP URNs, adds tags to RP fields, and adds to group 'DIG'" do
        expect(HTTParty).to receive(:post).with(
          "https://rapidpro.brl.nyc/api/v2/contacts.json?uuid=#{person.rapidpro_uuid}",
          headers: rapidpro_req_headers,
          body: {
            name: person.full_name,
            first_name: person.first_name,
            language: RapidproService.language_for_person(person),
            urns: ["tel:#{person.phone_number}", "mailto:#{person.email_address}"],
            groups: ["DIG"],
            fields: {
              tags: "tag_1 tag_2"
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
          "https://rapidpro.brl.nyc/api/v2/contacts.json?uuid=#{person.rapidpro_uuid}",
          headers: rapidpro_req_headers,
          body: {
            name: person.full_name,
            first_name: person.first_name,
            language: RapidproService.language_for_person(person),
            urns: ["tel:#{person.phone_number}"],
            groups: ["DIG"],
            fields: {
              tags: "tag_1 tag_2"
            }
          }.to_json
        )
        action
      end
    end
  end

  context "person doesn't have rapidpro_uuid" do
    it "finds contact on rapidpro through phone #" do
      person.update(rapidpro_uuid: nil)
      expect(HTTParty).to receive(:post).with(
        "https://rapidpro.brl.nyc/api/v2/contacts.json?urn=#{CGI.escape("tel:#{person.phone_number}")}",
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

  context "rapidpro responds with 201" do
    let(:rapidpro_res) { Hashie::Mash.new({
      code: 201,
      parsed_response: {
        uuid: 'fakeuuid'
      }
    }) }

    context "person has rapidpro_uuid" do
      it "does nothing" do
        expect(sut).not_to receive(:perform_in)
        action
      end
    end

    context "person doesn't have rapidpro_uuid yet" do
      it "sets rapidpro_uuid on person" do
        person.update(rapidpro_uuid: nil)
        expect(sut).not_to receive(:perform_in)
        action
        expect(person.reload.rapidpro_uuid).to eq('fakeuuid')
      end
    end
  end

  context "rapidpro responds with 429" do
    let(:rapidpro_res) { Hashie::Mash.new({
      code: 429,
      headers: {
        'retry-after': 100
      }
    }) }

    it "enqueues job to be retried" do
      expect(sut).to receive(:perform_in).with(100 + 5, person.id)
      action
    end
  end

  context "rapidpro responds with 200" do
    let(:rapidpro_res) { Hashie::Mash.new({
      code: 200
    }) }

    it "does nothing and returns true" do
      expect(sut).not_to receive(:perform_in)
      expect(action).to eq(true)
    end
  end

  context "rapidpro responds with unknown status" do
    let(:rapidpro_res) { Hashie::Mash.new({
      code: 666
    }) }

    it "raises error" do
      expect(sut).not_to receive(:perform_in)
      expect { action }.to raise_error(RuntimeError)
    end
  end
end
