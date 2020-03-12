# frozen_string_literal: true

require "rails_helper"

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

    click_link "New Person"
    expect(page).to have_selector(:link_or_button, "Create Person")

    fill_in "First name", with: first_name
    fill_in "Last name", with: last_name
    fill_in "Phone number", with: phone_number
    fill_in "Email address", with: email_address
    fill_in "Postal code", with: postal_code
    fill_in "Landline", with: landline
    check("Low income")
    select preferred_contact_method[:label], from: "Preferred contact method"
    select participation_type, from: "Participation type"
    # select verified, from: "Verified"
    click_button "Create Person"

    expect(page).to have_content(email_address)
    expect(page).to have_content(first_name)
    expect(page).to have_selector(:link_or_button, "Edit")

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

  scenario "create new, verified person, and edit their information" do
    add_new_person(verified: Person::VERIFIED_TYPE)
    assert_person_created(verified: Person::VERIFIED_TYPE)
    expect(page).to have_content(email_address)

    person = Person.order(:id).last

    # show person details page
    click_link person.full_name
    expect(page.current_path).to eq(person_path(person.id))

    # edit person's email
    updated_email_address = "eugeneupdated@asdf.com"
    find(:xpath, "//a[@href='#{edit_person_path(person.id)}']").click

    fill_in "Email address", with: updated_email_address
    click_button "Update Person"
    expect(page).to have_content("Person was successfully updated.")
    expect(page.current_path).to eq(person_path(person.id))
    expect(person.reload.email_address).to eq(updated_email_address)
    visit people_path
    expect(page).to have_content(updated_email_address)

    # non-admin can't reactivate/delete person
    admin_user.update(new_person_notification: false)
    visit people_path
    expect(page).not_to have_content(I18n.t("deactivate"))
    expect(page).not_to have_content("Delete")
    visit person_path(person.id)
    expect(page).not_to have_content(I18n.t("deactivate"))
    expect(page).not_to have_content("Delete")

    # admin can reactivate/delete person
    admin_user.update(new_person_notification: true)
    visit people_path
    expect(page).to have_content(I18n.t("deactivate"))
    expect(page).to have_content("Delete")
    visit person_path(person.id)
    expect(page).to have_content(I18n.t("deactivate"))
    expect(page).to have_content("Delete")

    # deactivate person
    expect(RapidproDeleteJob).to receive(:perform_async).with(person.id)
    find(:xpath, "//a[@href='#{deactivate_people_path(person.id)}']").click
    expect(page).to have_content("#{person.full_name} deactivated")
    expect(page).not_to have_content(updated_email_address)
    person.reload
    expect(person.active).to eq(false)
    expect(person.deactivated_at).to be_truthy
    expect(person.deactivated_method).to eq("admin_interface")

    # reactivate person
    expect(RapidproUpdateJob).to receive(:perform_async).with(person.id)
    visit person_path(person.id)
    expect(page).to have_content("#{person.full_name} | Deactivated")
    find(:xpath, "//a[@href='#{reactivate_people_path(person.id)}']").click
    expect(page.current_path).to eq(people_path)
    expect(page).to have_content("#{person.full_name} re-activated")
    expect(page).to have_content(updated_email_address)
    expect(person.reload.active).to eq(true)

    # delete person
    find(:xpath, "//a[@href='#{person_path(person.id)}' and @data-method='delete']").click
    expect(page.current_path).to eq(people_path)
    expect(page).not_to have_content(updated_email_address)
    expect { person.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  scenario "tagging", js: true do
    add_new_person(verified: Person::VERIFIED_TYPE)
    assert_person_created(verified: Person::VERIFIED_TYPE)
    expect(page).to have_content(email_address)

    person = Person.order(:id).last
    # show person details page
    click_link person.full_name
    expect(page.current_path).to eq(person_path(person.id))

    # add tag
    new_tag = "TeSt TaG"
    normalized_new_tag = new_tag.downcase
    fill_in with: new_tag, id: "tag-typeahead"
    find('.tag-form input[type="submit"]').native.send_keys(:return)
    wait_for_ajax
    person.reload
    expect(person.tag_list).to include(normalized_new_tag)
    expect(page).to have_content(normalized_new_tag)

    # look at search results by tag
    click_link normalized_new_tag
    expect(page).to have_content("Search Results")
    expect(page).to have_content(email_address)

    # delete tag
    click_link person.full_name
    created_tagging = person.taggings.order(:id).last
    find(:xpath, "//a[@href='#{tagging_path(created_tagging.id)}' and @data-method='delete']").click
    wait_for_ajax
    person.reload
    expect(person.tag_list).not_to include(normalized_new_tag)
    expect(page).not_to have_content(normalized_new_tag)
  end

  # this doesn't happen anymore though the in app form, only public
  xscenario "create new, unverified person" do
    add_new_person(verified: Person::NOT_VERIFIED_TYPE)
    assert_person_created(verified: Person::NOT_VERIFIED_TYPE)

    # admin users can see unverified people
    visit people_path
    expect(page).to have_content(email_address)

    # non-admin users can't see unverified people
    admin_user.update(new_person_notification: false)
    visit people_path
    expect(page).not_to have_content(email_address)
  end
end
