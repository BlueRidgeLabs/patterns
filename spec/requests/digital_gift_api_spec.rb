require 'rails_helper'

describe "digital_gift_api", type: :request do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:regular_user) { FactoryBot.create(:user) }
  
  let(:person) { FactoryBot.create(:person) }
  let(:research_session) { FactoryBot.create(:research_session, user: admin_user) }
  let(:headers) { {
      "ACCEPT" => "application/json",     # This is what Rails 4 accepts
      "HTTP_ACCEPT" => "application/json",
      'AUTHORIZATION' => admin_user.token # This is what Rails 3 accepts
    } }
  
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
  end

  it 'creates a digital gift for a research session with budget' do
    get "/digital_gifts/api_create", 
      headers: headers, 
      params:{
        phone_number: person.phone_number,
        research_session_id: research_session.id,
        amount: 25
      }
    byebug
    expect(response.content_type).to eq("application/json")
    
    body = JSON.parse(response.body)
    expect(body['success']).to eq(true)
    invitation.reload
    person.reload
    expect(person.rewards_total.to_s).to eq('25.00')
  end

  it 'cannot create a digital gift: insufficient budget' do
    get "/digital_gifts/api_create", 
      headers: headers, 
      params:{
        phone_number: person.phone_number,
        research_session_id: research_session.id,
        amount: 250
      }
    expect(response.content_type).to eq("application/json")
    invitation.reload
    person.reload
    expect(person.rewards_total.to_s).to_not eq('250.00')
  end
end
