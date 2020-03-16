# frozen_string_literal: true

# require 'capybara/selenium-webdriver'
Capybara.save_path = 'tmp/capybara/'

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless
# allows all elements to be seen by capybara, when js: true is set
Capybara.ignore_hidden_elements = false
# rubocop:disable all
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end
# rubocop:enable all

# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
