require 'rails_helper'
require 'faker'

feature 'Team Management' do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:user) {FactoryBot.create(:user)}
  let(:now) { DateTime.current }

  before do
    Timecop.freeze(now)
    login_with_admin_user(admin_user)
    user.save
    admin_user.save
  end

  after do
    Timecop.return
  end

  scenario 'lists teams' do
    visit '/admin/teams'
    expect(page).to have_content(admin_user.team.name)
    visit "/admin/teams/#{admin_user.team.id}"
    expect(page).to have_content admin_user.name
    expect(page).to have_content admin_user.team.finance_code
  end

  scenario 'create valid team' do
    visit '/admin/teams/new'

    fill_in 'Name', with: 'foo'
    fill_in 'Description', with: 'bar'
    select 'BRL', from: 'Finance code'
    click_button 'Create Team'
    team = Team.last
    expect(team.name).to eq('foo')
    expect(team.finance_code).to eq('BRL')
  end
  
  # driver not supported: trigger
  # scenario 'reassign user to a team', :js do
  #   visit '/admin/users'
  #   bip_select user, :team_id, admin_user.team.name
  #   user.reload
  #   expect(user.team.name).to eq(admin_user.team.name)
  # end
end
