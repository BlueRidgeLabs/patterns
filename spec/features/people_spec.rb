require 'rails_helper'

feature "people page" do
  let(:first_name) { "Doggo" }
  let(:last_name) { "Johnson" }
  let(:phone_number) { "6665551234" }
  let(:email_address) { "eugene@asdf.com" }
  let(:postal_code) { "11101" }
  let(:landline) { "6667772222" }
  let(:participation_type) { "remote" }

  def add_new_person(verified:)
    login_with_admin_user
    visit people_path

    click_link 'New Person'
    expect(page).to have_selector(:link_or_button, 'Create Person')

    fill_in 'First name', with: first_name
    fill_in 'Last name', with: last_name
    fill_in 'Phone number', with: phone_number
    fill_in 'Email address', with: email_address
    fill_in 'Postal code', with: postal_code
    fill_in 'Landline', with: landline
    select participation_type, from: 'Participation type'
    select verified, from: 'Verified'
    click_button 'Create Person'

    expect(page).to have_selector(:link_or_button, 'Update Person')

    visit people_path
  end

  def assert_person_created(verified:)
    new_person = Person.order(:id).last
    expect(new_person.first_name).to eq(first_name)
    expect(new_person.last_name).to eq(last_name)
    expect(new_person.phone_number).to eq("+1#{phone_number}")
    expect(new_person.email_address).to eq(email_address)
    expect(new_person.postal_code).to eq(postal_code)
    expect(new_person.landline).to eq("+1#{landline}")
    expect(new_person.participation_type).to eq(participation_type)
    expect(new_person.verified).to eq(verified)
  end

  scenario 'create new, verified person' do
    add_new_person(verified: Person::VERIFIED_TYPE)
    assert_person_created(verified: Person::VERIFIED_TYPE)
    expect(page).to have_content(email_address)
  end

  scenario 'create new, unverified person' do
    add_new_person(verified: Person::NOT_VERIFIED_TYPE)
    assert_person_created(verified: Person::NOT_VERIFIED_TYPE)
    # unverified people don't show up in list
    expect(page).not_to have_content(email_address)
  end  
end
