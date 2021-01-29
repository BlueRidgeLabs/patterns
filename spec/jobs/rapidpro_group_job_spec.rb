# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RapidproGroupJob, type: :job do
  let(:sut) { described_class }
  let(:rapidpro_base_uri) { "https://#{Rails.application.credentials.rapidpro[:domain]}/api/v2/" }
  let(:rapidpro_headers) do
    {
      'Authorization' => "Token #{Rails.application.credentials.rapidpro[:token]}",
      'Content-Type' => 'application/json'
    }
  end

  let(:person_on_rapidpro) { FactoryBot.create(:person, :rapidpro_syncable) }
  let(:person_not_on_rapidpro) { FactoryBot.create(:person, phone_number: nil) }
  let(:cart) do
    cart = FactoryBot.create(:cart, rapidpro_uuid: SecureRandom.uuid, rapidpro_sync: true)
    cart.people << person_on_rapidpro
    cart.people << person_not_on_rapidpro
    cart
  end

  let(:empty_cart) { FactoryBot.create(:cart, rapidpro_uuid: SecureRandom.uuid, rapidpro_sync: true) }

  context "action is 'create'" do
    context 'rapidpro sync false' do
      before { cart.update(rapidpro_sync: false) }

      it "doesn't do a damn thing" do
        expect(HTTParty).not_to receive(:delete)
        expect(sut).not_to receive(:perform_in)
        sut.new.perform(cart.id, 'create')
      end
    end

    context "rapidpro_uuid present, but group doesn't actually exist anymore" do
      it 'creates a new group on rapidpro and resets rapidpro_uuid' do
        allow_any_instance_of(sut).to receive(:find_group).and_return(false, true)
        expect(HTTParty).to receive(:post).with(
          "#{rapidpro_base_uri}groups.json",
          headers: rapidpro_headers,
          body: { name: cart.name }.to_json
        ).and_return(
          Hashie::Mash.new(
            code: 201,
            parsed_response: {
              'uuid' => 'newrapidprouuid'
            }
          )
        )
        expect(sut).not_to receive(:perform_in)
        expect(RapidproPersonGroupJob).to receive(:perform_async).with([person_on_rapidpro.id], cart.id, 'add')
        sut.new.perform(cart.id, 'create')
        expect(cart.reload.rapidpro_uuid).to eq('newrapidprouuid')
      end
    end

    context 'rapidpro_uuid present, and group does exist on rapid pro already' do
      it "doesn't create a new group, but does add all people on the cart, who have rapidpro uuids and a phone #, to the group" do
        allow_any_instance_of(sut).to receive(:find_group).and_return(true, true)
        expect(HTTParty).not_to receive(:post)
        expect(sut).not_to receive(:perform_in)
        expect(RapidproPersonGroupJob).to receive(:perform_async).with([person_on_rapidpro.id], cart.id, 'add')
        sut.new.perform(cart.id, 'create')
      end
    end

    context 'rate limit hit' do
      before { cart.update(rapidpro_uuid: nil) }

      it 're-queues job' do
        allow_any_instance_of(sut).to receive(:find_group).and_return(true)
        expect(HTTParty).to receive(:post).with(
          "#{rapidpro_base_uri}groups.json",
          headers: rapidpro_headers,
          body: { name: cart.name }.to_json
        ).and_return(
          Hashie::Mash.new(
            code: 429,
            headers: {
              'retry-after': 100
            }
          )
        )
        expect(sut).to receive(:perform_in).with(100 + 5, cart.id, 'create')
        expect(RapidproPersonGroupJob).not_to receive(:perform_async)
        sut.new.perform(cart.id, 'create')
        expect(cart.reload.rapidpro_uuid).to be_nil
      end
    end

    context 'rate limit not hit' do
      before { cart.update(rapidpro_uuid: nil) }

      it 'creates group, and adds all people on cart, who have rapidpro uuids and a phone #, to the group' do
        allow_any_instance_of(sut).to receive(:find_group).and_return(true)
        expect(HTTParty).to receive(:post).with(
          "#{rapidpro_base_uri}groups.json",
          headers: rapidpro_headers,
          body: { name: cart.name }.to_json
        ).and_return(
          Hashie::Mash.new(
            code: 201,
            parsed_response: {
              'uuid' => 'newrapidprouuid'
            }
          )
        )
        expect(sut).not_to receive(:perform_in)
        expect(RapidproPersonGroupJob).to receive(:perform_async).with([person_on_rapidpro.id], cart.id, 'add')
        sut.new.perform(cart.id, 'create')
        expect(cart.reload.rapidpro_uuid).to eq('newrapidprouuid')
      end
    end
  end

  context 'action is update' do
    before do
      expect(HTTParty).to receive(:get).with(
        "#{rapidpro_base_uri}groups.json",
        headers: rapidpro_headers
      ).and_return(Hashie::Mash.new(
                     parsed_response: {
                       'results' => [{
                         'uuid' => cart.rapidpro_uuid
                       }],
                       'next' => nil
                     }
                   ))
    end

    context 'cart is empty' do
      it 'does nothing' do
        expect(HTTParty).not_to receive(:post)
        expect(sut).not_to receive(:perform_in)
        sut.new.perform(empty_cart.id, 'update')
      end
    end

    xcontext 'cart has people without rapidpro uuids' do
      # right number of uuids, no nils
    end

    xcontext 'cart is not synced with rapidpro' do
      # httparty isn't called
    end

    context 'updates rapidpro' do
      it 'sends an http request' do
        expect(HTTParty).to receive(:post).with(
          "#{rapidpro_base_uri}contact_actions.json",
          headers: rapidpro_headers,
          body: {
            contacts: cart.people.map(&:rapidpro_uuid).compact,
            action: 'add',
            group: cart.rapidpro_uuid
          }.to_json
        ).and_return(Hashie::Mash.new(code: 200, parsed_response: { results: true }))
        expect(sut).not_to receive(:perform_in)
        sut.new.perform(cart.id, 'update')
      end
    end
  end

  context "action is 'delete'" do
    context 'rapidpro_uuid not present' do
      before { cart.update(rapidpro_uuid: nil) }

      it "doesn't do a damn thing" do
        expect(HTTParty).not_to receive(:delete)
        expect(sut).not_to receive(:perform_in)
        sut.new.perform(cart.id, 'delete')
      end
    end

    context 'unknown status returned from rapidpro' do
      it 'raises error' do
        rapidpro_ok_res = Hashie::Mash.new(code: 666)
        rapidpro_uri = "#{rapidpro_base_uri}groups.json?uuid=#{cart.rapidpro_uuid}"
        expect(HTTParty).to receive(:delete).with(rapidpro_uri, headers: rapidpro_headers).and_return(rapidpro_ok_res)
        expect(sut).not_to receive(:perform_in)
        expect { sut.new.perform(cart.id, 'delete') }.to raise_error(RuntimeError)
      end
    end

    context '404 returned from rapidpro' do
      it 'deletes cart.rapidpro_uuidd' do
        rapidpro_ok_res = Hashie::Mash.new(code: 404)
        rapidpro_uri = "#{rapidpro_base_uri}groups.json?uuid=#{cart.rapidpro_uuid}"
        expect(HTTParty).to receive(:delete).with(rapidpro_uri, headers: rapidpro_headers).and_return(rapidpro_ok_res)
        expect(sut).not_to receive(:perform_in)
        sut.new.perform(cart.id, 'delete')
      end
    end

    context 'rate limit hit' do
      it 're-queues job' do
        retry_delay = 100
        rapidpro_429_res = Hashie::Mash.new(code: 429, headers: { 'retry-after' => retry_delay })
        rapidpro_uri = "#{rapidpro_base_uri}groups.json?uuid=#{cart.rapidpro_uuid}"
        expect(HTTParty).to receive(:delete).with(rapidpro_uri, headers: rapidpro_headers).and_return(rapidpro_429_res)
        expect(sut).to receive(:perform_in).with(retry_delay + 5, cart.id, 'delete')
        sut.new.perform(cart.id, 'delete')
      end
    end

    context 'rate limit not hit' do
      it 'does not requeue job' do
        rapidpro_ok_res = Hashie::Mash.new(code: 204)
        rapidpro_uri = "#{rapidpro_base_uri}groups.json?uuid=#{cart.rapidpro_uuid}"
        expect(HTTParty).to receive(:delete).with(rapidpro_uri, headers: rapidpro_headers).and_return(rapidpro_ok_res)
        expect(sut).not_to receive(:perform_in)
        sut.new.perform(cart.id, 'delete')
      end
    end
  end

  describe 'helper methods' do
    describe '#find_group' do
      context 'a matching group exists' do
        it 'runs through all pages until it finds a matching group' do
          expect(HTTParty).to receive(:get).with("#{rapidpro_base_uri}groups.json", headers: rapidpro_headers).and_return(Hashie::Mash.new(
                                                                                                                            parsed_response: {
                                                                                                                              'results' => [{
                                                                                                                                'uuid' => 'otheruuid'
                                                                                                                              }],
                                                                                                                              'next' => 'nexturl'
                                                                                                                            }
                                                                                                                          ))
          expect(HTTParty).to receive(:get).with('nexturl', headers: rapidpro_headers).and_return(Hashie::Mash.new(
                                                                                                    parsed_response: {
                                                                                                      'results' => [{
                                                                                                        'uuid' => cart.rapidpro_uuid
                                                                                                      }],
                                                                                                      'next' => 'nexturl2'
                                                                                                    }
                                                                                                  ))
          expect(HTTParty).not_to receive(:get).with('nexturl2', headers: rapidpro_headers)
          _sut = sut.new
          # just calling this to initialize instance vars
          _sut.perform(cart.id, 'stub')
          expect(_sut.find_group).to eq(true)
        end
      end

      context 'a matching group does not exist' do
        it 'returns false' do
          expect(HTTParty).to receive(:get).with("#{rapidpro_base_uri}groups.json", headers: rapidpro_headers).and_return(Hashie::Mash.new(
                                                                                                                            parsed_response: {
                                                                                                                              'results' => [{
                                                                                                                                'uuid' => 'otheruuid'
                                                                                                                              }],
                                                                                                                              'next' => 'nexturl'
                                                                                                                            }
                                                                                                                          ))
          expect(HTTParty).to receive(:get).with('nexturl', headers: rapidpro_headers).and_return(Hashie::Mash.new(
                                                                                                    parsed_response: {
                                                                                                      'results' => [{
                                                                                                        'uuid' => 'otherotheruuid'
                                                                                                      }],
                                                                                                      'next' => nil
                                                                                                    }
                                                                                                  ))
          expect(HTTParty).not_to receive(:get).with('nexturl2', headers: rapidpro_headers)
          _sut = sut.new
          # just calling this to initialize instance vars
          _sut.perform(cart.id, 'stub')
          expect(_sut.find_group).to eq(false)
        end
      end
    end
  end
end
