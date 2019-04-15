require 'rails_helper'
describe "digtial_gift_api", type: :request do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:regular_user) {FactoryBot.create(:user) }
  let(:invitation) { FactoryBot.create(:invitation) }
  let(:person) { invitation.person }
  let(:research_session) { invitation.research_session }
  let(:headers) { {
      "ACCEPT" => "application/json",     # This is what Rails 4 accepts
      "HTTP_ACCEPT" => "application/json",
      'AUTHORIZATION' => admin_user.token # This is what Rails 3 accepts
    } }
  
  it 'creates a digital gift for a research session with budget' do
    get "/digital_gifts/api_create", headers: headers, params:{
      phone_number: person.phone_number
      research_session_id: research_session.id
    }
  end
end
