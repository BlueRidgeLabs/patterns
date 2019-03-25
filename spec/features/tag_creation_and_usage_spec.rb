require 'rails_helper'
require 'faker'
require 'support/chromedriver_setup'
require 'capybara/email/rspec'

feature 'tag person'  do
  before do
    @person = FactoryBot.create(:person)
  end

  scenario 'add tag', js: :true  do

    login_with_admin_user

    tag_name = Faker::Company.buzzword.downcase
    visit "/people/#{@person.id}"
    expect(page).to have_button('Add')

    fill_in_autocomplete '#tag-typeahead', tag_name

    find_button('Add').click
    wait_for_ajax
    sleep 1 # wait for our page to save
    # gotta reload so that we don't cache tags
    @person.reload
    found_tag = @person.tag_list.first ? @person.tag_list.first : false
    expect(found_tag).to eq(tag_name)

    visit "/people/#{@person.id}"
    # should have a deletable tag there.
    expect(page.evaluate_script("$('a.delete-link').length")).to eq(1)
  end

  scenario 'delete tag', js: :true  do
    
    tag_name = Faker::Company.buzzword.downcase
    @person.tag_list.add(tag_name)
    @person.save
    login_with_admin_user
    visit "/people/#{@person.id}"
    expect(page.evaluate_script("$('a.delete-link').length")).to eq(1)

    fill_in_autocomplete '#tag-typeahead', tag_name
    wait_for_ajax

    #expect(find(:css, '#tag-typeahead').value).to_not eq(tag_name)
    page.execute_script("$('a.delete-link').click();")
    wait_for_ajax
    sleep 1
    expect(page).to_not have_text(tag_name)
    @person.reload
    expect(@person.tag_list.to_s).to_not have_text(tag_name)
  end
end
