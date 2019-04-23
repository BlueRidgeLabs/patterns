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
    visit finance_code
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

  # TODO: non admin
end
