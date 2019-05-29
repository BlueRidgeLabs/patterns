# frozen_string_literal: true

# == Schema Information
#
# Table name: carts_people
#
#  cart_id   :bigint(8)        not null
#  person_id :bigint(8)        not null
#  id        :bigint(8)        not null, primary key
#

class CartsPerson < ApplicationRecord
  belongs_to :cart, counter_cache: :people_count
  belongs_to :person

  validates :person_id,
    uniqueness: { scope: :cart_id,
                  message: 'Person can only be in a cart once.' }

  if ENV['RAPIDPRO_TOKEN']
    after_create :add_to_rapidpro
    after_destroy :remove_from_rapidpro
  end

  def add_to_rapidpro
    RapidproPersonGroupJob.perform_async(person_id, cart.id, 'add')
  end

  def remove_from_rapidpro
    RapidproPersonGroupJob.perform_async(person_id, cart.id, 'remove')
  end
end
