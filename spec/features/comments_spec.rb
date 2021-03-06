# frozen_string_literal: true

require 'rails_helper'
require 'faker'

describe 'adding comments' do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:invitation) { FactoryBot.create(:invitation) }
  let(:person) { invitation.person }
  let(:comment_text) { Faker::Lorem.sentence }
  let(:now) { DateTime.now }

  before do
    Timecop.freeze(now)
    login_with_admin_user(admin_user)
  end

  it 'adding comments to a person', :js do
    visit "/people/#{person.id}"
    fill_in 'comment_content', with: comment_text
    click_button 'Add note'
    wait_for_ajax
    expect(page).to have_content(comment_text)
  end

  it 'adding comments to a research session', :js do
    visit "/sessions/#{invitation.research_session.id}"
    fill_in 'comment_content', with: comment_text
    click_button 'Add note'
    wait_for_ajax
    expect(page).to have_content(comment_text)
  end
end
