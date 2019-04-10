
require 'rails_helper'

feature "public person page" do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:now) { DateTime.current }
  let(:new_person) { {first_name: Faker::Name.first_name,
                      last_name: Faker::Name.last_name,
                      email_address: Faker::Internet.email,
                      phone_number: Faker::PhoneNumber.cell_phone,
                      postal_code: 11222,
                    }}
  
  scenario 'create new person' do
    visit '/public/people/new'
    fill_in 'First name', with: new_person[:first_name]
    fill_in 'Last name', with:  new_person[:last_name]
    fill_in 'Email address', with:  new_person[:email_address]
    fill_in 'Phone number', with:  new_person[:phone_number]
    select 'Email', from: 'Preferred contact method'
    select '26-40', from: 'age_range'
    fill_in 'Postal code', with: '11222'
    check 'person[low_income]'
    click_button 'Save'
    expect(page).to have_text('Thanks! We will be in touch soon!')
    last_person = Person.last
    expect(last_person.first_name).to eq(new_person[:first_name])
  end


end
