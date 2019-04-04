
require 'rails_helper'

feature "digital gifts page" do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:person) {FactoryBot.create(:person)}

  before do
    Timecop.freeze(now)
    login_with_admin_user(admin_user)
  end
  scenario 'top up budget', js: :true do
  end

  scenario 'transfer to user', js: :true do
  end

  scenario 'add to invitation', js: :true do
  end
end
