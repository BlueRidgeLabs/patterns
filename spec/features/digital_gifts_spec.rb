# frozen_string_literal: true

require 'rails_helper'

describe 'digital gifts page' do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:rs) { FactoryBot.create(:research_session, user: admin_user) }
  let(:invitation) do
    FactoryBot.create(:invitation,
                      research_session: rs)
  end
  let(:now) { DateTime.current }
  let(:rapidpro_headers) do
    {
      'ACCEPT' => 'application/json', # This is what Rails 4 accepts
      'HTTP_ACCEPT' => 'application/json',
      'AUTHORIZATION' => admin_user.token # This is what Rails 3 accepts
    }
  end

  let(:invalid_headers) do
    {
      'ACCEPT' => 'application/json', # This is what Rails 4 accepts
      'HTTP_ACCEPT' => 'application/json',
      'AUTHORIZATION' => user.token # This is what Rails 3 accepts
    }
  end

  before do
    Timecop.freeze(now)
    login_with_admin_user(admin_user)
  end
  # need to mock out the giftrocket gem.

  it 'top up budget', :vcr, js: :true do
    starting_amount = Budget.all.sum(&:amount)
    expected_amount = starting_amount + 100.to_money
    visit '/budgets'
    fill_in 'topup-amount', with: 100
    click_button 'Top Up'
    wait_for_ajax
    expect(Budget.all.sum(&:amount)).to eq(expected_amount)
  end

  it 'transfer to user', :vcr, :js do
    # don't like this whole bit here creating a budget.
    # should have a factory for this

    budget = user.team.budget
    original_amount = budget.amount
    visit '/budgets'
    fill_in 'topup-amount', with: 200
    click_button 'Top Up'
    wait_for_ajax
    expect(admin_user.budget.amount.to_s).to eq('200.00')

    fill_in 'transfer-amount', with: 100
    select admin_user.budget.name, from: 'from_id'
    select budget.name, from: 'recipient_id'
    click_button 'Transfer'
    wait_for_ajax
    budget.reload
    expect(budget.amount).to eq(original_amount + 100.to_money)
  end

  it 'add to invitation', :vcr, :js do
    research_session = invitation.research_session
    person = invitation.person

    # don't like this whole bit here creating a budget.
    # should have a factory for this
    visit '/budgets'
    fill_in 'topup-amount', with: 200
    click_button 'Top Up'
    wait_for_ajax

    Timecop.travel(research_session.end_datetime + 24.hours)
    visit "/sessions/#{research_session.id}"
    click_button 'attend'
    wait_for_ajax
    invitation.reload
    expect(invitation.aasm_state).to eq('attended')
    find("#add-reward-#{invitation.id}").click
    wait_for_ajax
    fill_in('new-amount', visible: true, with: 100)
    accept_alert do
      click_button 'Add Digital Gift'
    end
    wait_for_ajax
    person.reload
    expect(person.rewards_total.to_s).to eq('100.00')

    dg = person.rewards.last.rewardable
    expect(dg.sent).not_to eq(true)

    visit "/digital_gifts/#{dg.id}"
    accept_alert do
      click_button 'Not Yet'
    end
    wait_for_ajax
    dg.reload
    expect(dg.sent).to eq(true)
    visit '/digital_gifts/'
    expect(page).to have_text(dg.order_id)
    Timecop.freeze now
  end

  it 'insufficient team budget', :vcr, :js do
    do_top_up
    research_session = invitation.research_session
    person = invitation.person

    Timecop.travel(research_session.end_datetime + 24.hours)
    visit "/sessions/#{research_session.id}"
    click_button 'attend'
    wait_for_ajax
    invitation.reload
    expect(invitation.aasm_state).to eq('attended')
    find("#add-reward-#{invitation.id}").click
    wait_for_ajax
    fill_in('new-amount', visible: true, with: 100)
    accept_alert do
      click_button 'Add Digital Gift'
    end
    wait_for_ajax
    person.reload
    expect(person.rewards_total.to_s).not_to eq('100.00')
    Timecop.freeze now
  end

  it 'no digital gifts unless attended', :vcr, :js do
    do_top_up
    research_session = invitation.research_session
    Timecop.travel(research_session.end_datetime + 24.hours)

    visit "/sessions/#{research_session.id}"
    find("#add-reward-#{invitation.id}").click
    wait_for_ajax
    expect(page).not_to have_selector('new-amount', visible: true)
  end

  def do_top_up(amount = 100)
    visit '/budgets'
    fill_in 'topup-amount', with: amount
    click_button 'Top Up'
    wait_for_ajax
  end
end
