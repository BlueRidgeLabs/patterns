# frozen_string_literal: true

require 'rails_helper'
require 'faker'
require 'support/chromedriver_setup'
require 'capybara/email/rspec'

describe 'search using ransack' do
  before do
    @person_one = FactoryBot.create(:person, postal_code: '60606', preferred_contact_method: 'SMS')
    @person_two = FactoryBot.create(:person, postal_code: '60606', preferred_contact_method: 'SMS')
    @person_three = FactoryBot.create(:person, postal_code: '60606', preferred_contact_method: 'SMS')
  end

  it 'with no parameters' do
    login_with_admin_user
    visit '/search/index_ransack'
    page.find('#ransack-search').click
    count = Person.active.all.size
    expect(page).to have_text("Showing #{count} results of #{count} total")
  end

  it 'with matching parameters' do
    login_with_admin_user
    visit '/search/index_ransack'
    fill_in 'q_postal_code_start', with: '606'
    page.find('#ransack-search').click
    expect(page).to have_text(@person_one.first_name)
    expect(page).to have_text('Showing 3 results of 3 total')
  end

  it 'with no matching parameters' do
    login_with_admin_user
    visit '/search/index_ransack'
    fill_in 'q_postal_code_start', with: '901'
    page.find('#ransack-search').click
    expect(page).to have_text('There is no one that match your search')
  end

  it 'goes to the persons profile if only result' do
    login_with_admin_user
    visit '/search/index_ransack'
    fill_in 'q_full_name_cont', with: @person_three.first_name
    page.find('#ransack-search').click
    expect(page).to have_current_path("/people/#{@person_three.id}")
  end
  
  # scenario 'export search results to csv' do
  # end
end
