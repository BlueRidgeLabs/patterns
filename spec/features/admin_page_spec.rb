require 'rails_helper'

feature 'admin page' do
  let(:admin_user) { FactoryBot.create(:user, :admin) }

  before do
    login_with_admin_user(admin_user)
  end

  scenario "non admin" do
    admin_user.update(new_person_notification: false)
    visit root_path
    expect(page).not_to have_content("Admin Page")
    visit users_path
    expect(page.current_path).not_to eq(users_path)
    visit user_path(admin_user)
    expect(page.current_path).to eq(root_path)
    visit new_user_path(admin_user)
    expect(page.current_path).to eq(root_path)
    visit edit_user_path(admin_user)
    expect(page.current_path).to eq(root_path)
    visit user_changes_path
    expect(page.current_path).to eq(root_path)
    visit finance_code_path
    expect(page.current_path).to eq(root_path)
    # TODO: test other admin paths
      # http://localhost:3000/admin/people_amount
      # http://localhost:3000/admin/teams
      # http://localhost:3000/budgets
      # http://localhost:3000/cart
      # http://localhost:3000/admin/map
  end

  scenario "view user" do
    now = Time.zone.now
    distant_past_session = FactoryBot.create(:research_session, user: admin_user, start_datetime: now + 8.days)
    distant_future_session = FactoryBot.create(:research_session, user: admin_user, start_datetime: now - 8.days)
    near_past_session = FactoryBot.create(:research_session, user: admin_user, start_datetime: now + 4.days)
    near_future_session = FactoryBot.create(:research_session, user: admin_user, start_datetime: now - 4.days)
    other_user_session = FactoryBot.create(:research_session, start_datetime: now - 4.days)

    visit root_path
    click_link 'Admin Page'
    expect(page.current_path).to eq(users_path)
    within("#user-#{admin_user.id}") do
      expect(page).to have_content(admin_user.email)
      click_link 'Show'
    end
    expect(page.current_path).to eq(user_path(admin_user))
    expect(page).to have_content(admin_user.email)
    expect(page).not_to have_content(distant_past_session.title)
    expect(page).not_to have_content(distant_future_session.title)
    expect(page).to have_content(near_past_session.title)
    expect(page).to have_content(near_future_session.title)
    expect(page).not_to have_content(other_user_session.title)
  end

  scenario "creating a new user" do
    team = FactoryBot.create(:team)
    name = "Doggo Johnson"
    email = "doggo@johnson.com"
    phone_number = "  555-444-7777   "
    normalized_phone_number = "+15554447777"
    password = "asdfa989shdf"

    visit users_path
    click_link "New User"
    expect(page.current_path).to eq(new_user_path)

    fill_in 'Name', with: name
    fill_in 'Email address', with: email
    fill_in 'Phone number', with: phone_number
    select team.name, from: 'user_team_id'
    fill_in 'Password', with: password
    fill_in 'Password confirmation', with: password
    check 'Approved'
    click_button 'Create User'

    new_user = User.order(:id).last
    expect(page.current_path).to eq(user_path(new_user))
    expect(page).to have_content(I18n.t('user.successfully_created'))

    expect(new_user.name).to eq(name)
    expect(new_user.email).to eq(email)
    expect(new_user.phone_number).to eq(normalized_phone_number)
    expect(new_user.encrypted_password).to be_truthy
    expect(new_user.team).to eq(team)
    expect(new_user.approved).to eq(true)
    expect(new_user.current_cart.name).to eq("#{new_user.name}-pool")
    expect(new_user.approved).to eq(true)
    expect(new_user.token).to be_truthy
    expect(new_user.new_person_notification).to eq(false)
  end

  scenario "error creating user" do
    visit users_path
    click_link "New User"
    expect(page.current_path).to eq(new_user_path)

    click_button 'Create User'
    expect(page.current_path).to eq(users_path)
    within("form#new_user") do
      expect(page).to have_content("errors prohibited this user")
    end
  end

  def open_edit_form_for(user)
    visit user_path(user)
    click_link "Edit"
    expect(page.current_path).to eq(edit_user_path(user))
  end

  scenario "updating user" do
    new_name = "No Name"
    user = FactoryBot.create(:user)
    open_edit_form_for(user)
    fill_in 'Name', with: new_name
    click_button 'Update User'
    expect(page.current_path).to eq(user_path(user))
    expect(user.reload.name).to eq(new_name)
    expect(page).to have_content(I18n.t('user.successfully_updated'))
  end

  scenario "error updating user" do
    user = FactoryBot.create(:user)
    open_edit_form_for(user)
    fill_in 'Email address', with: ""
    click_button 'Update User'
    expect(page.current_path).to eq(user_path(user))
    within('form.edit_user') do
      expect(page).to have_content("Email can't be blank")
    end
  end

  scenario "changes" do
    with_versioning do
      expect(PaperTrail).to be_enabled
      user = FactoryBot.create(:user)
      user.update(name: "No Name")
      visit user_changes_path
      user.changes do |change|
        expect(page).to have_content(change.id)
      end
    end
  end
end
