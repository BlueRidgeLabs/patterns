require 'rails_helper'

feature "pools" do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:current_pool) { admin_user.current_cart }

  before do
    login_with_admin_user(admin_user)
  end

  def add_person_btn_for(person)
    page.find("#person-#{person.id}").find(:xpath, ".//a[@href='#{add_person_cart_index_path(person_id: person.id)}']")
  end

  def delete_person_btn_for(person)
    page.find("#person-#{person.id}").find(:xpath, ".//a[@href='#{delete_person_cart_index_path(person_id: person.id)}']")
  end

  scenario "add person to pool", js: true do
    person = FactoryBot.create(:person)
    visit people_path
    expect(page).to have_content(person.email_address)
    expect(page.find('.badge.cart-size').text).to have_content("0")
    expect(page.find('#pool-list').find(:xpath, ".//a[@href='#{cart_path(current_pool)}']")).to have_content("0")

    add_btn = add_person_btn_for(person)
    expect(add_btn).to have_content("Add")
    add_btn.click
    wait_for_ajax

    expect(page).to have_content("1 people added to #{current_pool.name}")
    expect(page.find('.badge.cart-size')).to have_content("1")

    # TODO: the test below currently fails. it asserts that when a person is added
    # to a pool, the counts within the "Your Pools" dropdown would update along
    # with the count in the "Current Pool" nav link. this is not currently the case,
    # but maybe in the future, we would care to build in that behavior.
    # expect(page.find('#pool-list').find(:xpath, ".//a[@href='#{cart_path(current_pool)}']")).to have_content("1")

    delete_btn = delete_person_btn_for(person)
    expect(delete_btn).to have_content("Remove")
    cart_btn = page.find('.current_cart')
    click_on(cart_btn)
    expect(page.current_path).to eq(cart_path(current_pool))
    expect(page).to have_content(person.email_address)
    within('.well') do
      expect(page.find('.cart-size')).to have_content("1")
    end

    # go to pool page
      # size 1
      # created by admin_user
      # sync to radidpro no
      # users
        # contains admin

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
