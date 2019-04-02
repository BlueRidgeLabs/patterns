
require 'rails_helper'

feature "gift_cards page" do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:valid_cc) {CreditCardValidations::Factory.random(:mastercard) }
  let(:valid_cc_2) {CreditCardValidations::Factory.random(:mastercard) }
  let(:invalid_cc) { '4853-9800-5973-0865' }
  let(:secure_code) { '034' }
  let(:expiration_date) { "12/24" }
  let(:amount) { '25.00' }
  let(:batch) { 771346 }
  let(:now) { DateTime.current }
  # let(:action_cable) { ActionCable.server }

  before do
    Timecop.freeze(now)
    login_with_admin_user(admin_user)
  end

  scenario 'add valid giftcard', js: :true do
    visit '/gift_cards'

    within '.new_card' do
      fill_in 'new_gift_cards__sequence_number', with: '1'
      fill_in 'new_gift_cards__full_card_number', with: valid_cc
      fill_in 'new_gift_cards__secure_code', with: secure_code
      fill_in 'new_gift_cards__expiration_date', with: expiration_date
      fill_in 'new_gift_cards__amount', with: amount
      fill_in 'new_gift_cards__batch_id', with: batch
    end

    find_button('Activate').click
    expect(page).to have_text('Card Activation process started.')
    expect(GiftCard.all.size).to eq(1)
    expect(GiftCard.last.full_card_number).to eq(valid_cc)
    # expect(action_cable).to receive(:broadcast)
  end

  scenario 'add valid giftcards', js: :true do
    visit '/gift_cards'

    within '.new_card' do
      fill_in 'new_gift_cards__sequence_number', with: '1'
      fill_in 'new_gift_cards__full_card_number', with: valid_cc
      fill_in 'new_gift_cards__secure_code', with: secure_code
      fill_in 'new_gift_cards__expiration_date', with: expiration_date
      fill_in 'new_gift_cards__amount', with: amount
      fill_in 'new_gift_cards__batch_id', with: batch
    end
    find_by_id('add-gift-card-row').click

    expect(page).to have_selector(".new_card",count:2)
    
    within(all('.new_card').last) do      
      fill_in 'new_gift_cards__full_card_number', with: valid_cc_2
    end

    find_button('Activate').click

    expect(page).to have_text('Card Activation process started.')
    expect(GiftCard.all.size).to eq(2)
  end

  scenario 'add invalid giftcard', js: :true do
    visit '/gift_cards'

    within '.new_card' do
      fill_in 'new_gift_cards__sequence_number', with: '1'
      fill_in 'new_gift_cards__full_card_number', with: invalid_cc
      fill_in 'new_gift_cards__secure_code', with: secure_code
      fill_in 'new_gift_cards__expiration_date', with: expiration_date
      fill_in 'new_gift_cards__amount', with: amount
      fill_in 'new_gift_cards__batch_id', with: batch
    end
    # button should be deactivated
    expect(page).to have_no_button('Activate')
  end

  scenario 'change card owner', js: :true do
    gift_card = FactoryBot.create(:gift_card, user: admin_user)
    other_user = FactoryBot.create(:user)
    visit '/gift_cards'
    expect(page).to have_text(gift_card.last_4)

    select other_user.name, from: "user_change_gift_card_#{gift_card.id}"

    wait_for_ajax
    #FIXME 
    #TODO
    sleep 1 # hate this
    gift_card.reload
    expect(gift_card.user.id).to eq(other_user.id)

  end

end
