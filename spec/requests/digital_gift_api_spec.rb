# frozen_string_literal: true

require 'rails_helper'

describe 'digital_gift_api', type: :request do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:regular_user) { FactoryBot.create(:user) }

  let(:person) { FactoryBot.create(:person, :rapidpro_syncable) }
  let(:inactive_person) { FactoryBot.create(:person, :rapidpro_syncable, active: false) }
  let(:research_session) { FactoryBot.create(:research_session, user: admin_user) }
  let(:headers) do
    {
      'ACCEPT' => 'application/json', # This is what Rails 4 accepts
      'HTTP_ACCEPT' => 'application/json',
      'AUTHORIZATION' => admin_user.token # This is what Rails 3 accepts
    }
  end

  before do
    TransactionLog.create(amount: 100,
                          transaction_type: 'Topup',
                          # all recipients here are budgets. No Digital Gifts
                          recipient_type: 'Budget',
                          recipient_id: admin_user.budget.id,
                          from_id: admin_user.id,
                          from_type: 'User',
                          user_id: admin_user.id)
    research_session.tag_list.add('survey')
    research_session.save
    research_session.reload
  end

  it 'creates a digital gift for a research session with budget', :vcr do
    get '/digital_gifts/api_create',
        headers: headers,
        params: {
          rapidpro_uuid: person.rapidpro_uuid,
          research_session_id: research_session.id,
          amount: 25
        }

    expect(response.content_type).to eq('application/json; charset=utf-8')
    body = JSON.parse(response.body)
    expect(body['success']).to eq(true)

    person.reload
    dg = person.rewards.last.rewardable
    expect(body['link']).to eq(dg.link)
    expect(dg.sent).to eq(true)
    expect(person.rewards_total.to_s).to eq('25.00')
  end

  it 'cannot create a digital gift: insufficient budget', :vcr do
    get '/digital_gifts/api_create',
        headers: headers,
        params: {
          rapidpro_uuid: person.rapidpro_uuid,
          research_session_id: research_session.id,
          amount: 250
        }
    expect(response.content_type).to eq('application/json; charset=utf-8')
    body = JSON.parse(response.body)
    expect(body['success']).to eq(false)
    expect(body['msg']).to include('insufficent budget')
    person.reload
    expect(person.rewards_total.to_s).to_not eq('250.00')
  end

  it 'cannot create a digital gift for a non-admin', :vcr do
    get '/digital_gifts/api_create',
        headers: {
          'ACCEPT' => 'application/json', # This is what Rails 4 accepts
          'HTTP_ACCEPT' => 'application/json',
          'AUTHORIZATION' => regular_user.token # This is what Rails 3 accepts
        },
        params: {
          phone_number: person.phone_number,
          research_session_id: research_session.id,
          amount: 25
        }
    expect(response.content_type).to eq('application/json; charset=utf-8')
    expect(response.status).to eq(401)
    person.reload
    expect(person.rewards_total.to_s).to_not eq('250.00')
  end

  it 'cannot create a digital gift for a non-existant user', :vcr do
    get '/digital_gifts/api_create',
        headers: {
          'ACCEPT' => 'application/json', # This is what Rails 4 accepts
          'HTTP_ACCEPT' => 'application/json',
          'AUTHORIZATION' => 'bogustoken' # This is what Rails 3 accepts
        },
        params: {
          phone_number: person.phone_number,
          research_session_id: research_session.id,
          amount: 25
        }
    expect(response.content_type).to eq('application/json; charset=utf-8')
    expect(response.status).to eq(401)
    person.reload
    expect(person.rewards_total.to_s).to_not eq('250.00')
  end

  it 'cannot create a digital gift without a token', :vcr do
    get '/digital_gifts/api_create',
        headers: {
          'ACCEPT' => 'application/json',     # This is what Rails 4 accepts
          'HTTP_ACCEPT' => 'application/json'
        },
        params: {
          phone_number: person.phone_number,
          research_session_id: research_session.id,
          amount: 25
        }
    expect(response.content_type).to eq('application/json; charset=utf-8')
    expect(response.status).to eq(401)
    person.reload
    expect(person.rewards_total.to_s).to_not eq('250.00')
  end

  it 'cannot create a digital gift for an inactive person', :vcr do
    get '/digital_gifts/api_create',
        headers: {
          'ACCEPT' => 'application/json',     # This is what Rails 4 accepts
          'HTTP_ACCEPT' => 'application/json',
          'AUTHORIZATION' => regular_user.token
        },
        params: {
          rapidpro_uuid: inactive_person.rapidpro_uuid,
          research_session_id: research_session.id,
          amount: 25
        }
    expect(response.content_type).to eq('application/json; charset=utf-8')
    expect(response.status).to eq(401)

    person.reload
    expect(person.rewards_total.to_s).to_not eq('250.00')
  end

  it 'cannot create a digital gift for a non-existant research session', :vcr do
    get '/digital_gifts/api_create',
        headers: headers,
        params: {
          rapidpro_uuid: person.rapidpro_uuid,
          research_session_id: research_session.id + 1,
          amount: 25
        }
    expect(response.content_type).to eq('application/json; charset=utf-8')
    expect(response.status).to eq(201)
    person.reload
    expect(person.rewards_total.to_s).to_not eq('250.00')
  end
end
