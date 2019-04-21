require 'rails_helper'

feature "research sessions" do
  let(:admin_user) { FactoryBot.create(:user, :admin) }

  before do
    login_with_admin_user(admin_user)
  end

  def go_to_session_form
    visit root_path
    click_link 'New Session'
    expect(page.current_path).to eq(new_research_session_path)
  end

  def fill_session_form(user:, title: "fake title", location: nil, description: "fake desc", start_datetime: Time.zone.now, duration: ResearchSession::DURATION_OPTIONS.first)
    select user.name, from: 'research_session_user_id'
    fill_in 'Session Title', with: title
    fill_in 'Session Location', with: location
    fill_in 'Session description', with: description
    fill_in 'Start datetime', with: start_datetime.strftime('%Y-%m-%d %H:%M %p')
    select duration, from: 'research_session_duration'
  end

  def pool_label(pool)
    "#{pool.name}: #{pool.people.count}"
  end

  scenario "creating a new session, with location" do
    approved_user = FactoryBot.create(:user)
    unapproved_user = FactoryBot.create(:user, :unapproved)
    title = "fake title"
    location = "BRL"
    description = "fake description"
    start_datetime = Time.zone.now.beginning_of_minute + 2.days
    duration = ResearchSession::DURATION_OPTIONS.first

    # create new session
    go_to_session_form
    within('#research_session_user_id') do
      expect(page).to have_content(approved_user.name)
      expect(page).not_to have_content(unapproved_user.name)
    end
    within('#research_session_duration') do
      ResearchSession::DURATION_OPTIONS.each do |duration_option|
        expect(page).to have_content(duration_option)
      end
    end

    fill_session_form({
      user: approved_user,
      title: title,
      location: location,
      description: description,
      start_datetime: start_datetime,
      duration: duration
    })
    click_button 'Create'

    # verify created correctly
    new_research_session = ResearchSession.order(:id).last
    expect(new_research_session.title).to eq(title)
    expect(new_research_session.location).to eq(location)
    expect(new_research_session.description).to eq(description)
    expect(new_research_session.start_datetime).to be_within(1.seconds).of(start_datetime)
    expect(new_research_session.end_datetime).to be_within(1.seconds).of(start_datetime + duration.minutes)
    expect(new_research_session.duration).to eq(duration)
    expect(page.current_path).to eq(research_session_path(new_research_session))
    expect(page).to have_content(new_research_session.title)
  end

  scenario "creating a new session, without location" do
    go_to_session_form
    fill_session_form({ user: admin_user, location: nil })
    click_button 'Create'

    new_research_session = ResearchSession.order(:id).last
    expect(new_research_session.location).to eq(I18n.t(
      'research_session.call_location',
      name: admin_user.name,
      phone_number: admin_user.phone_number
    ))
  end

  scenario "create a new session, with people", js: true do
    # create two new pools for user
    pool_1 = FactoryBot.create(:cart, user: admin_user)
    pool_2 = FactoryBot.create(:cart, user: admin_user)
    pool_1.people << person_1a = FactoryBot.create(:person)
    pool_1.people << person_1b = FactoryBot.create(:person)
    pool_2.people << person_2a = FactoryBot.create(:person)
    pool_2.people << person_2b = FactoryBot.create(:person)

    # create pool for other user
    pool_3 = FactoryBot.create(:cart)

    visit new_research_session_path
    fill_session_form({ user: admin_user })

    # expect current user's pools to be selectable
    within("#cart") do
      expect(page).to have_content(pool_label(pool_1))
      expect(page).to have_content(pool_label(pool_2))
      expect(page).not_to have_content(pool_label(pool_3))
    end

    # select pool 1
    select pool_label(pool_1), from: "cart"
    wait_for_ajax
    within("#mini-cart") do
      expect(page).to have_content(person_1a.full_name)
      expect(page).to have_content(person_1b.full_name)
    end

    # add all from pool 1
    click_with_js(page.find('#add_all'))
    wait_for_ajax
    within("#people-store") do
      expect(page).to have_content(person_1a.full_name)
      expect(page).to have_content(person_1b.full_name)
    end

    # remove all from pool 1
    click_with_js(page.find('#remove_all'))
    wait_for_ajax
    within("#people-store") do
      expect(page).not_to have_content(person_1a.full_name)
      expect(page).not_to have_content(person_1b.full_name)
    end

    # add person 1 from pool 1
    click_with_js(page.find("#add-#{person_1a.id}"))
    wait_for_ajax
    within('#people-store') do
      expect(page).to have_content(person_1a.full_name)
    end

    # remove person 1 from pool 1
    click_with_js(page.find("#remove-person-#{person_1a.id}"))
    wait_for_ajax
    within('#people-store') do
      expect(page).not_to have_content(person_1a.full_name)
    end

    # add person 1 from pool 1 again
    click_with_js(page.find("#add-#{person_1a.id}"))
    wait_for_ajax

    # switch to pool 2
    select pool_label(pool_2), from: "cart"

    # add both person 1 from pool 2
    click_with_js(page.find("#add-#{person_2a.id}"))

    # create
    click_button 'Create'
    new_research_session = ResearchSession.order(:id).last
    invitations = new_research_session.invitations

    # expect invitations created along with research session
    expect(invitations.length).to eq(2)
    invitation_1a = invitations.find_by(person: person_1a)
    invitation_2a = invitations.find_by(person: person_2a)
    expect(invitation_1a).to be_truthy
    expect(invitation_2a).to be_truthy
    expect(invitation_1a.aasm_state).to eq('created')
    expect(invitation_2a.aasm_state).to eq('created')
  end

  # TODO: test errors
end
