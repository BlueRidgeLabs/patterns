# frozen_string_literal: true

require 'factory_bot_rails' # use factories!
require 'faker'
# Make some dummy people
if Rails.env.development?
  100.times { FactoryBot.create :person }

  FactoryBot.create :research_session

  FactoryBot.create :invitation

  team = Team.create(name: 'Regular Team', finance_code: 'FELL  ')

  User.create(
    email: 'user@example.com',
    password: 'foobar123!01203$#$%R',
    password_confirmation: 'foobar123!01203$#$%R',
    approved: true,
    new_person_notification: false,
    name: 'Joe User',
    team_id: team.id,
    phone_number: '555-555-5555'
  )

  admin_team = Team.create(name: 'Admin Team', finance_code: 'BRL')

  User.create(
    email: 'admin@example.com',
    password: 'foobar123!01203$#$%R',
    password_confirmation: 'foobar123!01203$#$%R',
    approved: true,
    new_person_notification: true,
    name: 'Admin User',
    team_id: admin_team.id,
    phone_number: '555-555-5555'
  )
end
