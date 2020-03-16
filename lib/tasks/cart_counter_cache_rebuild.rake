# frozen_string_literal: true

desc 'Counter cache for project has many tasks'

task cart_people_counter: :environment do
  Cart.reset_column_information
  Cart.select(:id).find_each do |p|
    Cart.reset_counters p.id, :people
  end
end
