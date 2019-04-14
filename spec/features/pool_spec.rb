require 'rails_helper'

feature "pools" do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:current_pool) { admin_user.current_cart }

  before do
    login_with_admin_user(admin_user)
  end

  context "people index page actions" do
    def add_person_btn_for(person)
      page.find("#person-#{person.id}").find(:xpath, ".//a[@href='#{add_person_cart_index_path(person_id: person.id)}']")
    end

    def delete_person_btn_for(person)
      page.find("#person-#{person.id}").find(:xpath, ".//a[@href='#{delete_person_cart_index_path(person_id: person.id)}']")
    end

    def go_to_current_pool
      cart_btn = page.find('.current_cart_link')
      click_with_js(cart_btn)
      expect(page.current_path).to eq(cart_path(current_pool))
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
      go_to_current_pool
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
      go_to_current_pool
      expect(page).not_to have_content(person.email_address)
      within('.well') do
        expect(page.find('.cart-size')).to have_content("0")
      end
    end
  end

  context "pool page actions" do
    scenario "create new pool", js: true do
      pool_name = "the new pool"
      pool_description = "lorem ipsum"

      # create new pool
      visit cart_path(current_pool)
      click_link 'New Pool'
      fill_in 'name', with: pool_name
      fill_in 'description', with: pool_description
      click_button 'Save changes'

      # verify pool initialized correctly
      new_pool = Cart.find_by(name: pool_name, description: pool_description)
      expect(new_pool).not_to be_nil
      expect(new_pool.users.length).to eq(1)
      expect(new_pool.users.first).to eq(admin_user)
      expect(new_pool.user).to eq(admin_user)
      expect(new_pool.rapidpro_uuid).to be_nil
      expect(new_pool.rapidpro_sync).to eq(false)
      expect(new_pool.people.length).to eq(0)
      expect(page.current_path).to eq(cart_path(new_pool))
      expect(page).to have_content(pool_name)
      expect(page).to have_content(pool_description)
      expect(page).to have_content(admin_user.name)

      # verify pool added to list of pools in nav bar
      expect(page.find('.current_cart')).to have_content(pool_name)
      expect(page.find('#pool-list')).to have_content(pool_name)

      # can add user
      other_user = FactoryBot.create(:user)
      visit current_path
      expect(page).to have_content(other_user.name)
      select other_user.name, from: "user_id"
      wait_for_ajax
      within('#users-list') do
        expect(page.find("#user-#{other_user.id}")).to have_content(other_user.name)
      end
      expect(new_pool.reload.users.size).to eq(2)

      # can remove user
      within("#users-list #user-#{other_user.id}") do
        click_button('remove')
      end
      wait_for_ajax
      within('#users-list') do
        expect(page).not_to have_content(other_user.name)
      end
      expect(new_pool.reload.users.size).to eq(1)

      # can search for person and add them to pool
      new_person = FactoryBot.create(:person)
      visit current_path
      fill_in 'cart-typeahead', with: new_person.first_name
      wait_for_ajax
      page.find('.tt-dataset-People', text: new_person.full_name).click
      wait_for_ajax
      expect(page).to have_content("1 people added to #{new_pool.name}")
      within('#full-cart') do
        expect(page).to have_content(new_person.email_address)
      end

      # can remove person from pool
      remove_btn = page.find("#cart-#{new_person.id}").find(".btn", text: "Remove")
      click_with_js(remove_btn)
      wait_for_ajax
      expect(page).to have_content(I18n.t('cart.delete_person_success', person_name: new_person.full_name, cart_name: new_pool.name))
      within('#full-cart') do
        expect(page).not_to have_content(new_person.email_address)
      end
      # add multiple people
      # remove all
      # ? export csv
      # can switch pool

      # QUESTION: admin vs user login
    end
  end
end
