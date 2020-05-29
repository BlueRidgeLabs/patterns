# frozen_string_literal: true

require 'rails_helper'

describe 'research sessions' do
  let(:admin_user) { FactoryBot.create(:user, :admin) }

  before do
    login_with_admin_user(admin_user)
  end

  def go_to_session_form
    visit root_path
    click_link 'New Session'
    expect(page).to have_current_path(new_research_session_path, ignore_query: true)
  end

  def fill_session_form(user:, title: 'fake title', location: nil, description: 'fake desc', start_datetime: Time.zone.now, duration: ResearchSession::DURATION_OPTIONS.first)
    select user.name, from: 'research_session_user_id'
    fill_in 'Session Title', with: title
    fill_in 'Session Location', with: location
    fill_in 'Session description', with: description
    # we use a datepicker, so we hide the actual datetime field
    if page.driver.class == Capybara::Selenium::Driver # dumb, but the element doesn't appear otherwise
      find('.today').click
    else
      find("//*[@id=\'research_session_start_datetime\']", visible: false).set(start_datetime.strftime('%Y-%m-%d %H:%M %p'))
    end
    # page.execute_script("document.getElementById('research_session_start_datetime').value = '#{start_datetime.strftime("%Y-%m-%d %H:%M %p")}';")
    select duration, from: 'research_session_duration'
  end

  def pool_label(pool)
    "#{pool.name}: #{pool.people.count}"
  end

  it 'creating a new session, with location' do
    approved_user = FactoryBot.create(:user)
    unapproved_user = FactoryBot.create(:user, :unapproved)
    title = 'fake title'
    location = 'BRL'
    description = 'fake description'
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

    fill_session_form(
      user: approved_user,
      title: title,
      location: location,
      description: description,
      start_datetime: start_datetime,
      duration: duration
    )
    click_button 'Create'

    # verify created correctly
    new_research_session = ResearchSession.order(:id).last
    expect(new_research_session.title).to eq(title)
    expect(new_research_session.location).to eq(location)
    expect(new_research_session.description).to eq(description)
    expect(new_research_session.start_datetime).to be_within(1.second).of(start_datetime)
    expect(new_research_session.end_datetime).to be_within(1.second).of(start_datetime + duration.minutes)
    expect(new_research_session.duration).to eq(duration)
    expect(page).to have_current_path(research_session_path(new_research_session), ignore_query: true)
    expect(page).to have_content(new_research_session.title)
  end

  it 'creating a new session, without location' do
    go_to_session_form
    fill_session_form(user: admin_user, location: nil)
    click_button 'Create'

    new_research_session = ResearchSession.order(:id).last
    expect(new_research_session.location).to eq(I18n.t(
                                                  'research_session.call_location',
                                                  name: admin_user.name,
                                                  phone_number: admin_user.phone_number
                                                ))
  end

  xit 'create a new session, with people', js: true do
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
    fill_session_form(user: admin_user)

    # expect current user's pools to be selectable
    within('#cart') do
      expect(page).to have_content(pool_label(pool_1))
      expect(page).to have_content(pool_label(pool_2))
      expect(page).not_to have_content(pool_label(pool_3))
    end

    # select pool 1
    select pool_label(pool_1), from: 'cart'
    wait_for_ajax
    within('#mini-cart') do
      expect(page).to have_content(person_1a.full_name)
      expect(page).to have_content(person_1b.full_name)
    end

    # add all from pool 1
    click_with_js(page.find('#add_all'))
    wait_for_ajax
    within('#people-store') do
      expect(page).to have_content(person_1a.full_name)
      expect(page).to have_content(person_1b.full_name)
    end

    # remove all from pool 1
    click_with_js(page.find('#remove_all'))
    wait_for_ajax
    within('#people-store') do
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
    select pool_label(pool_2), from: 'cart'

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
    visit research_sessions_path
    expect(page).to have_content(new_research_session.title)
  end

  it 'errors when creating a new session' do
    go_to_session_form
    click_button 'Create'
    expect(page).to have_content("There were problems with some of the fields: Description can't be blank, Title can't be blank, Start datetime can't be blank")
    expect(ResearchSession.count).to eq(0)
  end

  def add_invitee(person)
    within('#mini-cart') do
      click_with_js(page.find("#add-person-#{person.id}"))
    end
    wait_for_ajax
    within('.invitees') do
      expect(page).to have_content(person.full_name)
    end
  end

  def remove_invitee(person)
    within('#mini-cart') do
      click_with_js(page.find("#remove-person-#{person.id}"))
    end
    wait_for_ajax
    within('.invitees') do
      expect(page).not_to have_content(person.full_name)
    end
  end

  def assert_invitee_actions_exist(actions)
    actions.each do |action|
      expect(page).to have_xpath("//input[@value='#{action}']")
    end
  end

  def assert_invitee_action_works(invitation:, action:, new_state:, new_actions:)
    within("#invitation-#{invitation.id}-actions") do
      action_btn = page.find(:xpath, "//input[@value='#{action}']")
      click_with_js(action_btn)
      wait_for_ajax
      assert_invitee_actions_exist(new_actions)
    end
    expect(page).to have_content(I18n.t(
                                   'invitation.event_success',
                                   event: action.capitalize,
                                   person_name: invitation.person.full_name
                                 ))
    expect(invitation.reload.aasm_state).to eq(new_state)
  end

  it 'invitee actions', js: true do
    gift_card = FactoryBot.create(:gift_card, :active, user: admin_user)
    start_datetime = DateTime.current + 2.days
    research_session = FactoryBot.create(:research_session, start_datetime: start_datetime)
    current_cart = admin_user.current_cart
    current_cart.people << person_1 = FactoryBot.create(:person)
    current_cart.people << person_2 = FactoryBot.create(:person)
    visit research_session_path(research_session)

    # expect current pool's people to be visible, for selection
    within('#mini-cart') do
      expect(page).to have_content(person_1.full_name)
      expect(page).to have_content(person_2.full_name)
    end

    # invite person 1
    add_invitee(person_1)
    invitation_1 = research_session.reload.invitations.find_by(person: person_1)
    expect(invitation_1).to be_truthy
    expect(invitation_1.aasm_state).to eq('created')
    expect(page).to have_content(I18n.t(
                                   'research_session.add_invitee_success',
                                   person_name: person_1.full_name
                                 ))
    within("#invitation-#{invitation_1.id}-actions") do
      assert_invitee_actions_exist(['invite'])
    end

    # person 1, invite!
    assert_invitee_action_works(
      invitation: invitation_1,
      action: 'invite',
      new_state: 'invited',
      new_actions: %w[remind confirm cancel]
    )

    # person 1, remind!
    assert_invitee_action_works(
      invitation: invitation_1,
      action: 'remind',
      new_state: 'reminded',
      new_actions: %w[remind confirm cancel]
    )

    # person 1, confirm!
    assert_invitee_action_works(
      invitation: invitation_1,
      action: 'confirm',
      new_state: 'confirmed',
      new_actions: %w[confirm cancel]
    )

    Timecop.travel(invitation_1.start_datetime + 2.hours)
    visit research_session_path(research_session)
    # person 1, attend!
    assert_invitee_action_works(
      invitation: invitation_1,
      action: 'attend',
      new_state: 'attended',
      new_actions: ['attend']
    )
    Timecop.return
    # uninvite person 1
    remove_invitee(person_1)
    expect(research_session.reload.invitations.count).to eq(0)
    expect(page).to have_content(I18n.t('research_session.remove_invitee_success', person_name: person_1.full_name))

    # reinvite person 1
    add_invitee(person_1)
    invitation_1 = research_session.reload.invitations.find_by(person: person_1)
    # person 1, invite, and cancel!
    assert_invitee_action_works(
      invitation: invitation_1,
      action: 'invite',
      new_state: 'invited',
      new_actions: %w[remind confirm cancel]
    )
    assert_invitee_action_works(
      invitation: invitation_1,
      action: 'cancel',
      new_state: 'cancelled',
      new_actions: []
    )

    # invite person 2
    add_invitee(person_2)
    invitation_2 = research_session.reload.invitations.find_by(person: person_2)
    assert_invitee_actions_exist(['invite'])

    click_with_js(page.find("#add-reward-#{invitation_2.id}"))
    expect(page).to have_content("Rewards:#{invitation_2.person.full_name}")

    click_with_js(page.find('#modal-footer-close'))

    expect(page).not_to have_selector('#modal-window', visible: true)

    # travel far past the session date
    Timecop.freeze(start_datetime + 1.day) do
      visit current_path
      within("#invitation-#{invitation_2.id}-actions") do
        assert_invitee_actions_exist(%w[attend miss])
      end
      assert_invitee_action_works(
        invitation: invitation_2,
        action: 'miss',
        new_state: 'missed',
        new_actions: ['attend']
      )

      # click_with_js(page.find("#add-reward-#{invitation_2.id}"))
      # expect(page).to have_content(gift_card.last_4)
      # fill_in 'card-search', with: gift_card.sequence_number.to_i + 4
      # sleep 0.25
      # expect(page).not_to have_content(gift_card.last_4)
    end
  end

  it 'cloning a session' do
    research_session = FactoryBot.create(:research_session)
    visit research_session_path(research_session)
    click_link I18n.t('research_session.clone_btn')
    expect(page).to have_current_path(research_session_clone_path(research_session), ignore_query: true)

    expect(page).to have_select('research_session_user_id', selected: admin_user.name)
    expect(find_field('research_session_title').value).to eq research_session.title
    expect(find_field('research_session_location').value).to eq research_session.location
    expect(find_field('research_session_description').value).to eq research_session.description
    expect(find_field('research_session_start_datetime').value).to eq research_session.start_datetime.strftime('%Y-%m-%d %H:%M:%S %z')
    expect(find_field('research_session_duration').value).to eq research_session.duration.to_s
  end
end
