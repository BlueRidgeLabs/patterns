require 'rails_helper'

feature 'People registration' do

  scenario 'Without signup' do
    visit '/registration'

    # fill_in 'Name', :with => 'My Widget'
    # click_button 'Create Widget'

    # expect(page).to have_text('Widget was successfully created.')
  end
end
