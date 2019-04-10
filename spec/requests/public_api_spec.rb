require "rails_helper"

describe "public_api", :type => :request do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:first_name) { "Doggo" }
  let(:last_name) { "Johnson" }
  let(:phone_number) { "6665551234" }
  let(:email_address) { "eugene@asdf.com" }
  let(:postal_code) { "11101" }
  let(:neighborhood) { "doggotown" }
  let(:landline) { "6667772222" }
  let(:participation_type) { "remote" }
  let(:tags) {'foo,bar,baz' }
  let(:preferred_contact_method) { { value: "SMS", label: "Text Message" } }
  let(:low_income) { true }
  let(:person) { FactoryBot.create(:person) } 

  it "creates person through the API" do
    headers = {
      "ACCEPT" => "application/json",     # This is what Rails 4 accepts
      "HTTP_ACCEPT" => "application/json",
      'AUTHORIZATION' => admin_user.token # This is what Rails 3 accepts
    }
    post "/api/create_person", params: {:tags => tags,
                                        :first_name => first_name,
                                        :last_name => last_name,
                                        :preferred_contact_method => 'SMS',
                                        :postal_code => postal_code,
                                        :email_address => email_address,
                                        :low_income => true,
                                        :phone_number => phone_number,},
                                        headers: headers

    expect(response.content_type).to eq("application/json")
    expect(response).to have_http_status(:created)

    expect(Person.last.first_name).to eq('Doggo')
  end

  it "updates person through API" do
     headers = {
      "ACCEPT" => "application/json",     # This is what Rails 4 accepts
      "HTTP_ACCEPT" => "application/json", # This is what Rails 3 accepts
      'AUTHORIZATION' => admin_user.token
    }

    post "/api/update_person", 
          params: { phone_number: person.phone_number, 
                    tags:'bat,bonk',
                    note:'this is a note',
                    first_name: 'Pupper'
                  },
          headers: headers
    expect(response.content_type).to eq("application/json")
    
    person.reload
    
    expect(person.first_name).to_not eq('Doggo')
    expect(person.first_name).to eq('Pupper')
    
  end
end
