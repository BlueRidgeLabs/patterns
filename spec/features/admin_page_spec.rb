# frozen_string_literal: true

require 'rails_helper'

describe 'admin page' do
  let(:admin_user) { FactoryBot.create(:user, :admin) }

  before do
    login_with_admin_user(admin_user)
  end

  it 'non admin' do
    admin_user.update(new_person_notification: false)
    visit root_path
    expect(page).not_to have_content('Admin Page')
    visit users_path
    expect(page).to have_no_current_path(users_path, ignore_query: true)
    visit user_path(admin_user)
    expect(page).to have_current_path(root_path, ignore_query: true)
    visit new_user_path(admin_user)
    expect(page).to have_current_path(root_path, ignore_query: true)
    visit edit_user_path(admin_user)
    expect(page).to have_current_path(root_path, ignore_query: true)
    visit user_changes_path
    expect(page).to have_current_path(root_path, ignore_query: true)
    visit finance_code_path
    expect(page).to have_current_path(root_path, ignore_query: true)
    visit budgets_path
    expect(page).to have_current_path(root_path, ignore_query: true)

    # broken in testing
    # visit people_map_path
    # expect(page).to have_current_path(root_path, ignore_query: true)
    visit people_amount_path
    expect(page).to have_current_path(root_path, ignore_query: true)
    visit teams_path
    expect(page).to have_current_path(root_path, ignore_query: true)

    visit new_team_path
    expect(page).to have_current_path(root_path, ignore_query: true)
    visit new_user_path
    expect(page).to have_current_path(root_path, ignore_query: true)

    # huh, wonder why this doesn't work.
    # visit sidekiq_web_path
    # expect(page).to have_current_path(root_path, ignore_query: true)
  end

  it 'view user' do
    now = Time.zone.now
    distant_past_session = FactoryBot.create(:research_session, user: admin_user, start_datetime: now + 8.days)
    distant_future_session = FactoryBot.create(:research_session, user: admin_user, start_datetime: now - 8.days)
    near_past_session = FactoryBot.create(:research_session, user: admin_user, start_datetime: now + 4.days)
    near_future_session = FactoryBot.create(:research_session, user: admin_user, start_datetime: now - 4.days)
    other_user_session = FactoryBot.create(:research_session, start_datetime: now - 4.days)

    visit root_path
    click_link 'Admin Page'
    expect(page).to have_current_path(users_path, ignore_query: true)
    within("#user-#{admin_user.id}") do
      expect(page).to have_content(admin_user.email)
      click_link 'Show'
    end
    expect(page).to have_current_path(user_path(admin_user), ignore_query: true)
    expect(page).to have_content(admin_user.email)
    expect(page).not_to have_content(distant_past_session.title)
    expect(page).not_to have_content(distant_future_session.title)
    expect(page).to have_content(near_past_session.title)
    expect(page).to have_content(near_future_session.title)
    expect(page).not_to have_content(other_user_session.title)
  end

  it 'creating a new user' do
    team = FactoryBot.create(:team)
    name = 'Doggo Johnson'
    email = 'doggo@johnson.com'
    phone_number = '  555-444-7777   '
    normalized_phone_number = '+15554447777'
    password = 'asdfa989shdf'

    visit users_path
    click_link 'New User'
    expect(page).to have_current_path(new_user_path, ignore_query: true)

    fill_in 'Name', with: name
    fill_in 'Email address', with: email
    fill_in 'Phone number', with: phone_number
    select team.name, from: 'user_team_id'
    fill_in 'Password', with: password
    fill_in 'Password confirmation', with: password
    check 'Approved'
    click_button 'Create User'

    new_user = User.order(:id).last
    expect(page).to have_current_path(user_path(new_user), ignore_query: true)
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

  it 'error creating user', retry: 3 do
    visit users_path
    click_link 'New User'
    expect(page).to have_current_path(new_user_path, ignore_query: true)

    click_button 'Create User'
    expect(page).to have_current_path(users_path, ignore_query: true)
    within('form#new_user') do
      expect(page).to have_content('errors prohibited this user')
    end
  end

  def open_edit_form_for(user)
    visit user_path(user)
    click_link 'Edit'
    expect(page).to have_current_path(edit_user_path(user), ignore_query: true)
  end

  it 'updating user' do
    new_name = 'No Name'
    user = FactoryBot.create(:user)
    open_edit_form_for(user)
    fill_in 'Name', with: new_name
    click_button 'Update User'
    expect(page).to have_current_path(user_path(user), ignore_query: true)
    expect(user.reload.name).to eq(new_name)
    expect(page).to have_content(I18n.t('user.successfully_updated'))
  end

  it 'error updating user' do
    user = FactoryBot.create(:user)
    open_edit_form_for(user)
    fill_in 'Email address', with: ''
    click_button 'Update User'
    expect(page).to have_current_path(user_path(user), ignore_query: true)
    within('form.edit_user') do
      expect(page).to have_content("Email can't be blank")
    end
  end

  # NOTE: (EL) skipping because, for whatever reason, including papertrail's rspec
  # helper breaks a bunch of other tests
  xit 'changes page' do
    with_versioning do
      expect(PaperTrail).to be_enabled
      user = FactoryBot.create(:user)
      user.update(name: 'No Name')
      visit user_changes_path
      user.changes do |change|
        expect(page).to have_content(change.id)
      end
    end
  end

  it 'finance page' do
    now = Time.current
    finance_code_1 = Team::FINANCE_CODES[0]
    finance_code_2 = Team::FINANCE_CODES[1]
    Timecop.travel(now - 1.year)
    fc_1_old_reward = FactoryBot.create(:reward, :gift_card, amount_cents: 50_00, finance_code: finance_code_1)
    fc_2_old_reward = FactoryBot.create(:reward, :gift_card, amount_cents: 50_00, finance_code: finance_code_2)
    Timecop.travel(now)

    fc_1_recent_reward_1 = FactoryBot.create(:reward, :gift_card, amount_cents: 100_00, finance_code: finance_code_1)
    fc_1_recent_reward_2 = FactoryBot.create(:reward, :gift_card, amount_cents: 200_00, finance_code: finance_code_1)
    fc_1_recent_reward_3 = FactoryBot.create(:reward, :gift_card, amount_cents: 300_00, finance_code: finance_code_1)
    fc_2_recent_reward_1 = FactoryBot.create(:reward, :gift_card, amount_cents: 400_00, finance_code: finance_code_2)
    fc_2_recent_reward_2 = FactoryBot.create(:reward, :gift_card, amount_cents: 500_00, finance_code: finance_code_2)

    visit finance_code_path

    expect(page).to have_content('$1,500')
    # expect(page).to have_content(now.to_date.to_s)
    expect(page).to have_content(now.beginning_of_year.to_date.to_s)
    within("#finance-code-#{finance_code_1}") do
      expect(page.find('.finance-code__code')).to have_content(3)
      expect(page.find('.finance-code__amount')).to have_content('$600')
    end
    within("#finance-code-#{finance_code_2}") do
      expect(page.find('.finance-code__code')).to have_content(2)
      expect(page.find('.finance-code__amount')).to have_content('$900')
    end
  end
end
