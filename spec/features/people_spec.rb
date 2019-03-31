require 'rails_helper'

feature "people page" do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:first_name) { "Doggo" }
  let(:last_name) { "Johnson" }
  let(:phone_number) { "6665551234" }
  let(:email_address) { "eugene@asdf.com" }
  let(:postal_code) { "11101" }
  let(:neighborhood) { "doggotown" }
  let(:landline) { "6667772222" }
  let(:participation_type) { "remote" }
  let(:preferred_contact_method) { { value: "SMS", label: "Text Message" } }
  let(:low_income) { true }
  let(:last_person) { }

  let(:now) { DateTime.current }

  before do
    Timecop.freeze(now)
    allow_any_instance_of(Person).to receive(:zip_to_neighborhood).and_return(neighborhood)
    login_with_admin_user(admin_user)
  end

  after do
    Timecop.return
  end

  def add_new_person(verified:)
    visit people_path

    click_link 'New Person'
    expect(page).to have_selector(:link_or_button, 'Create Person')

    fill_in 'First name', with: first_name
    fill_in 'Last name', with: last_name
    fill_in 'Phone number', with: phone_number
    fill_in 'Email address', with: email_address
    fill_in 'Postal code', with: postal_code
    fill_in 'Landline', with: landline
    check('Low income')
    select preferred_contact_method[:label], from: 'Preferred contact method'
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
    expect(new_person.neighborhood).to eq(neighborhood)
    expect(new_person.created_by).to eq(admin_user.id)
    expect(new_person.screening_status).to eq("new")
    expect(new_person.signup_at).to be_within(1.seconds).of(now)
    expect(new_person.token).to be_truthy
    expect(new_person.preferred_contact_method).to eq(preferred_contact_method[:value])
    expect(new_person.low_income).to eq(low_income)
  end

  scenario 'create new, verified person, and edit their information' do
    add_new_person(verified: Person::VERIFIED_TYPE)
    assert_person_created(verified: Person::VERIFIED_TYPE)
    expect(page).to have_content(email_address)

    # edit person's email
    person = Person.order(:id).last
    updated_email_address = "eugeneupdated@asdf.com"
    find(:xpath, "//a[@href='#{edit_person_path(person.id)}']").click

    fill_in 'Email address', with: updated_email_address
    click_button 'Update Person'
    expect(page).to have_content('Person was successfully updated.')
    expect(page.current_path).to eq(person_path(person.id))
    expect(person.reload.email_address).to eq(updated_email_address)
    visit people_path
    expect(page).to have_content(updated_email_address)

    # deactivate person
    expect(RapidproDeleteJob).to receive(:perform_async).with(person.id)
    find(:xpath, "//a[@href='#{deactivate_people_path(person.id)}']").click
    expect(page).to have_content("#{person.first_name} #{person.last_name} deactivated")
    expect(page).not_to have_content(updated_email_address)
    person.reload
    expect(person.active).to eq(false)
    expect(person.deactivated_at).to be_truthy
    expect(person.deactivated_method).to eq('admin_interface')
  end

  scenario 'create new, unverified person' do
    add_new_person(verified: Person::NOT_VERIFIED_TYPE)
    assert_person_created(verified: Person::NOT_VERIFIED_TYPE)
    # unverified people don't show up in list
    expect(page).not_to have_content(email_address)
  end

  scenario 'delete person' do
  end

  scenario 'deactivate person' do
  end

  scenario 'edit person' do
  end

  scenario 'search people by tag' do
  end
end
