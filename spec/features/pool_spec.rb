require 'rails_helper'

feature "pools" do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:current_pool) { admin_user.current_cart }

  before do
    login_with_admin_user(admin_user)
  end

  scenario "add person to pool", js: true do
    person = FactoryBot.create(:person)
    visit people_path
    expect(page).to have_content(person.email_address)
    expect(page.find('.badge.cart-size').text).to have_content("0")


    # expect(page.find('#pool-list').find(:xpath, ".//a[@href='#{cart_path(current_pool)}']")).to have_content("0")
    #
    # add_btn = page.find("#person-#{person.id}").find(:xpath, ".//a[@href='#{add_person_cart_index_path(person_id: person.id)}']")
    # expect(add_btn).to have_content("Add")
    # add_btn.click
    # expect(page).to have_content("1 people added to #{current_pool.name}-pool")
    # expect(page.find('.badge.cart-size')).to have_content("1")
    # expect(page.find('#pool-list').find(:xpath, ".//a[@href='#{cart_path(current_pool)}']")).to have_content("1")
    #
    # delete_btn = page.find("#person-#{person.id}").find(:xpath, ".//a[@href='#{delete_person_cart_index_path(person_id: person.id)}']")
    # expect(delete_btn).to have_content("Remove")


      # flash message
      # pool (1)
    # go to pool page
      # size 1
      # created by admin_user
      # sync to radidpro no
      # users
        # contains admin
      # person email exists in list

    # click remove
      # add btn shown
      # flash message
      # pool (0)
    # go to pool page
      # size 0
      # email not present
      # all the rest same
  end
end
