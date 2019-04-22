require 'rails_helper'

describe "calendar feed", type: :request do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:regular_user) { FactoryBot.create(:user) }
  let(:invitation) { FactoryBot.create(:invitation) }
  let(:invitation_user){ invitation.user }
  let(:research_session) { invitation.research_session }
  let(:now) { DateTime.current }

  before do
    Timecop.freeze(now)
    invitation.save
    research_session.save
  end

  it 'for admins, it includes ical events' do
    get "/calendar/#{admin_user.token}/admin_feed"
    
    expect(response.status).to eq(200)
    expect(response.content_type).to eq("text/plain")
    expect(response.body).to include(research_session.description)
  end
  
  it 'invalid tokens do not work' do
    get "/calendar/bustedtoken/admin_feed"
    expect(response.status).to_not eq(200)
    expect(response.body).to_not include(research_session.description)
  end

  it 'for regular feed, it includes ical events' do
    get "/calendar/#{invitation_user.token}/feed"
    
    expect(response.status).to eq(200)
    expect(response.content_type).to eq("text/plain")
    expect(response.body).to include(research_session.description)
  end
  
  it 'has feed for person' do 
    get "/calendar/#{invitation.person.token}/feed"
    expect(response.status).to eq(200)
    expect(response.content_type).to eq("text/plain")
    expect(response.body).to include(research_session.description)
  end
end
