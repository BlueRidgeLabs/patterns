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

    # confirm that current pool is empty
    visit people_path
    expect(page).to have_content(person.email_address)
    expect(page.find('.badge.cart-size').text).to have_content("0")
    expect(page.find('#pool-list').find(:xpath, ".//a[@href='#{cart_path(current_pool)}']")).to have_content("0")

    # add person to current pool
    add_btn = add_person_btn_for(person)
    expect(add_btn).to have_content("Add")
    add_btn.click
    wait_for_ajax
    expect(page).to have_content("1 people added to #{current_pool.name}")
    expect(page.find('.badge.cart-size')).to have_content("1")
    delete_btn = delete_person_btn_for(person)
    expect(delete_btn).to have_content("Remove")
    # TODO: the test below currently fails. it asserts that when a person is added
    # to a pool, the counts within the "Your Pools" dropdown would update along
    # with the count in the "Current Pool" nav link. this is not currently the case,
    # but maybe in the future, we would care to build in that behavior. the solution would
    # just involve adding the .cart-size class to the links in #pool-list, so that
    # add.js.erb can manage them.
    # expect(page.find('#pool-list').find(:xpath, ".//a[@href='#{cart_path(current_pool)}']")).to have_content("1")

    # current pool page reflects recent addition
    cart_btn = page.find('.current_cart')
    click_on(cart_btn)
    expect(page.current_path).to eq(cart_path(current_pool))
    expect(page).to have_content(person.email_address)
    within('.well') do
      expect(page.find('.cart-size')).to have_content("1")
    end
  end

  scenario "delete person from pool", js: true do
    person = FactoryBot.create(:person)
    current_pool.people << person

    # confirm that pool is initialized with one person
    visit people_path
    expect(page).to have_content(person.email_address)
    expect(page.find('.badge.cart-size').text).to have_content("1")
    expect(page.find('#pool-list').find(:xpath, ".//a[@href='#{cart_path(current_pool)}']")).to have_content("1")

    # remove person from pool
    delete_btn = delete_person_btn_for(person)
    expect(delete_btn).to have_content("Remove")
    delete_btn.click
    wait_for_ajax
    expect(page.find('.badge.cart-size')).to have_content("0")
    expect(page).to have_content(I18n.t('cart.delete_person_success', person_name: person.full_name, cart_name: current_pool.name))
    add_btn = add_person_btn_for(person)
    expect(add_btn).to have_content("Add")

    # current pool page reflects recent removal
    cart_btn = page.find('.current_cart')
    click_on(cart_btn)
    expect(page.current_path).to eq(cart_path(current_pool))
    expect(page).not_to have_content(person.email_address)
    within('.well') do
      expect(page.find('.cart-size')).to have_content("0")
    end
  end
end
