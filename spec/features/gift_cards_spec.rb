# frozen_string_literal: true

require 'rails_helper'

describe 'gift_cards page' do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:valid_cc) { CreditCardValidations::Factory.random(:mastercard) }
  let(:valid_cc_2) { CreditCardValidations::Factory.random(:mastercard) }
  let(:invalid_cc) { '4853-9800-5973-0865' }
  let(:secure_code) { '034' }
  let(:expiration_date) { '12/24' }
  let(:amount) { '25.00' }
  let(:batch) { 771_346 }
  let(:now) { DateTime.current }
  # let(:action_cable) { ActionCable.server }

  before do
    Timecop.freeze(now)
    login_with_admin_user(admin_user)
  end

  it 'preload cards' do
    visit '/gift_cards/preloaded'
    within '.preload-cards' do
      fill_in 'seq_start', with: 1
      fill_in 'seq_end', with: 10
      fill_in 'batch_id', with: batch
      fill_in 'expiration_date', with: expiration_date
      fill_in 'amount', with: amount
    end

    click_button 'Preload'
    visit '/gift_cards/preloaded'
    expect(GiftCard.preloaded.size).to eq(10)
    expect(page).to have_content(batch)
    expect(page).to have_content(admin_user.name)
    visit '/gift_cards'
    expect(page).not_to have_content(batch)
  end

  it 'activate preloaded cards', :js do
    gc = FactoryBot.create(:gift_card, :preloaded, user_id: admin_user.id)
    visit '/gift_cards'
    find('.activate-toggle').click
    # page.driver.browser.execute_script("$('#manual_card').toggle()")

    within '.new_card' do
      fill_in 'new_gift_cards__full_card_number', with: valid_cc
      fill_in 'new_gift_cards__secure_code', with: secure_code
    end
    click_button 'Activate'
    gc.reload
    expect(gc.status).not_to eq('preload')
    expect(gc.status).to eq('activate_started')
    expect(gc.full_card_number).to eq(valid_cc)
    expect(gc.secure_code).to eq(secure_code)
  end

  it 'change preloaded cards users', :js do
    gift_card = FactoryBot.create(:gift_card, :preloaded, user_id: admin_user.id)
    other_user = FactoryBot.create(:user)
    visit '/gift_cards/preloaded'

    select other_user.name, from: "user_change_gift_card_#{gift_card.id}"

    wait_for_ajax
    # FIXME
    # TODO
    sleep 1 # hate this
    gift_card.reload
    expect(gift_card.user.id).to eq(other_user.id)
    visit '/gift_cards/preloaded'
    expect(page).to have_content(other_user.name)
  end

  # scenario 'add valid giftcard', js: :true do
  #   visit '/gift_cards'

  #   within '.new_card' do
  #     fill_in 'new_gift_cards__sequence_number', with: '1'
  #     fill_in 'new_gift_cards__full_card_number', with: valid_cc
  #     fill_in 'new_gift_cards__secure_code', with: secure_code
  #     fill_in 'new_gift_cards__expiration_date', with: expiration_date
  #     fill_in 'new_gift_cards__amount', with: amount
  #     fill_in 'new_gift_cards__batch_id', with: batch
  #   end

  #   find_button('Activate').click
  #   expect(page).to have_text('Card Activation process started.')
  #   expect(GiftCard.all.size).to eq(1)
  #   expect(GiftCard.last.full_card_number).to eq(valid_cc)
  #   # expect(action_cable).to receive(:broadcast)
  # end

  # scenario 'add valid giftcards', js: :true do
  #   visit '/gift_cards'

  #   within '.new_card' do
  #     fill_in 'new_gift_cards__sequence_number', with: '1'
  #     fill_in 'new_gift_cards__full_card_number', with: valid_cc
  #     fill_in 'new_gift_cards__secure_code', with: secure_code
  #     fill_in 'new_gift_cards__expiration_date', with: expiration_date
  #     fill_in 'new_gift_cards__amount', with: amount
  #     fill_in 'new_gift_cards__batch_id', with: batch
  #   end
  #   find_by_id('add-gift-card-row').click

  #   expect(page).to have_selector(".new_card",count:2)

  #   within(all('.new_card').last) do
  #     fill_in 'new_gift_cards__full_card_number', with: valid_cc_2
  #   end

  #   find_button('Activate').click

  #   expect(page).to have_text('Card Activation process started.')
  #   expect(GiftCard.all.size).to eq(2)
  # end

  # scenario 'add invalid giftcard', js: :true do
  #   visit '/gift_cards'

  #   within '.new_card' do
  #     fill_in 'new_gift_cards__sequence_number', with: '1'
  #     fill_in 'new_gift_cards__full_card_number', with: invalid_cc
  #     fill_in 'new_gift_cards__secure_code', with: secure_code
  #     fill_in 'new_gift_cards__expiration_date', with: expiration_date
  #     fill_in 'new_gift_cards__amount', with: amount
  #     fill_in 'new_gift_cards__batch_id', with: batch
  #   end
  #   # button should be deactivated
  #   expect(page).to have_no_button('Activate')
  # end

  it 'change card owner', js: :true do
    gift_card = FactoryBot.create(:gift_card, :active, user: admin_user)
    other_user = FactoryBot.create(:user)
    visit '/gift_cards'
    expect(page).to have_text(gift_card.last_4)

    select other_user.name, from: "user_change_gift_card_#{gift_card.id}"

    wait_for_ajax
    # FIXME
    # TODO
    sleep 1 # hate this
    gift_card.reload
    expect(gift_card.user.id).to eq(other_user.id)
  end

  it 'edit card' do
    gift_card = FactoryBot.create(:gift_card, :active, user: admin_user)

    visit "/gift_cards/#{gift_card.id}"
    expect(page).to have_content(gift_card.batch_id)
    expect(page).to have_content(gift_card.last_4)
    visit "/gift_cards/#{gift_card.id}/edit"
    fill_in 'Secure code', with: '001'
    click_button 'Update Gift card'
    gift_card.reload
    expect(gift_card.secure_code).to eq('001')
  end
end
