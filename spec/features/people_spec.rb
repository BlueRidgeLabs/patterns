require 'rails_helper'

feature "people page" do
  let(:first_name) { "Doggo" }
  let(:last_name) { "Johnson" }
  let(:phone_number) { "6665551234" }
  let(:email_address) { "eugene@asdf.com" }
  let(:postal_code) { "11101" }
  let(:landline) { "6667772222" }
  let(:participation_type) { "remote" }

  scenario 'create new person' do
    login_with_admin_user
    visit '/people'

    click_link 'New Person'
    expect(page).to have_selector(:link_or_button, 'Create Person')

    fill_in 'First name', with: first_name
    fill_in 'Last name', with: last_name
    fill_in 'Phone number', with: phone_number
    fill_in 'Email address', with: email_address
    fill_in 'Postal code', with: postal_code
    fill_in 'Landline', with: landline
    select participation_type, from: 'Participation type'
    select Person::VERIFIED_TYPE, from: 'Verified'
    click_button 'Create Person'
    expect(page).to have_selector(:link_or_button, 'Update Person')

    new_person = Person.order(:id).last
    expect(new_person.first_name).to eq(first_name)
    expect(new_person.last_name).to eq(last_name)
    expect(new_person.phone_number).to eq("+1#{phone_number}")
    expect(new_person.email_address).to eq(email_address)
    expect(new_person.postal_code).to eq(postal_code)
    expect(new_person.landline).to eq("+1#{landline}")
    expect(new_person.participation_type).to eq(participation_type)
    expect(new_person.verified).to eq(Person::VERIFIED_TYPE)

    visit people_path
    expect(page).to have_content(email_address)
  end
end
