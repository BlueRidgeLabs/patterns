require 'rails_helper'

feature "research sessions" do
  let(:admin_user) { FactoryBot.create(:user, :admin) }

  before do
    login_with_admin_user(admin_user)
  end

  scenario "creating a new session" do
    approved_user = FactoryBot.create(:user)
    unapproved_user = FactoryBot.create(:user, :unapproved)
    title = "fake title"
    location = "BRL"
    description = "fake description"
    date = DateTime.current + 2.days
    duration = ResearchSession::DURATION_OPTIONS.first

    # create new session
    visit root_path
    click_link 'New Session'
    expect(page.current_path).to eq(new_research_session_path)
    within('#research_session_user_id') do
      expect(page).to have_content(approved_user.name)
      expect(page).not_to have_content(unapproved_user.name)
    end
    within('#research_session_duration') do
      ResearchSession::DURATION_OPTIONS.each do |duration_option|
        expect(page).to have_content(duration_option)
      end
    end
    select approved_user.name, from: 'research_session_user_id'
    fill_in 'Session Title', with: title
    fill_in 'Session Location', with: location
    fill_in 'Session description', with: description
    fill_in 'Start datetime', with: date.strftime('%Y-%m-%d %H:%M %p')
    select duration, from: 'research_session_duration'
    click_button 'Create'

    # verify created correctly
    new_research_session = ResearchSession.order(:id).last
    expect(page.current_path).to eq(research_session_path(new_research_session))
    # in session list
  end
end
