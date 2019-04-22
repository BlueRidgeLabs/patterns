require 'rails_helper'

feature 'admin page' do
  let(:admin_user) { FactoryBot.create(:user, :admin) }

  before do
    login_with_admin_user(admin_user)
  end

  scenario "" do
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
