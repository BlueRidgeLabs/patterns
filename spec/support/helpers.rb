# frozen_string_literal: true

module Helpers
  def login_with_admin_user(user = FactoryBot.create(:user))
    visit '/users/sign_in'
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  def fill_in_autocomplete(selector, value)
    el = find(selector)
    el.native.send_keys(*value.chars)
  end

  def choose_autocomplete(text)
    find('.tt-selectable').has_content?(text).click
    find(".tt-selectable:contains('#{text}').a").click
  end

  def wait_for_ajax
    sleep 0.1
    counter = 0
    while page.execute_script('return $.active').to_i > 0
      counter += 1
      sleep(0.1)
      raise 'AJAX request took longer than 5 seconds.' if counter >= 50
    end
  end

  def click_with_js(element)
    element.execute_script('this.click()')
  end
end
