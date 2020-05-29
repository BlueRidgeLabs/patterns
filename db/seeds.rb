# frozen_string_literal: true

# Make some dummy people
if Rails.env.development?
  Person.create(
    first_name: 'Jim',
    last_name: 'Tester',
    email_address: 'jim@example.com',
    address_1: '150 Court st.',
    city: 'Brooklyn',
    state: 'NY',
    postal_code: '11222',
    geography_id: '', # ward
    primary_device_id: 1,
    primary_device_description: 'Apple Macbook Pro',
    secondary_device_id: 2,
    secondary_device_description: 'Samsung Galaxy',
    primary_connection_id: 1,
    primary_connection_description: 'cable internet',
    phone_number: '312-555-9090',
    participation_type: 'in-person',
    preferred_contact_method: 'EMAIL',
    token: 'thisismytoken2'
  )

  Person.create(
    first_name: 'Jane',
    last_name: 'Developer',
    email_address: 'jane@example.com',
    address_1: '1060 W Addison',
    city: 'Chicago',
    state: 'IL',
    postal_code: '60613',
    geography_id: '44', # ward
    primary_device_id: 1,
    primary_device_description: 'iPad',
    secondary_device_id: 2,
    secondary_device_description: 'Apple laptop',
    primary_connection_id: 1,
    primary_connection_description: 'cable internet',
    phone_number: '312-555-8888',
    participation_type: 'remote',
    preferred_contact_method: 'SMS',
    token: 'thisismytoken'
  )

  team = Team.create(name: 'patterns', finance_code: 'BRL')
  user = User.create(
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
  admin = User.create(
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
