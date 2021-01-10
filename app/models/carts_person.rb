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

  after_create :add_to_rapidpro, if: :do_rapidpro_sync?
  after_destroy :remove_from_rapidpro, if: :do_rapidpro_sync?

  # only if rapidpro gets out of sync/db resets, etc.
  def self.update_all_rapidpro
    CartsPerson.includes(:cart).all.find_each do |cp|
      next unless cp.cart.rapidpro_sync

      RapidproPersonGroupJob.perform_async(cp.person_id, cp.cart_id, 'add')
    end
  end

  def add_to_rapidpro
    RapidproPersonGroupJob.perform_async(person_id, cart.id, 'add')
  end

  def remove_from_rapidpro
    RapidproPersonGroupJob.perform_async(person_id, cart.id, 'remove')
  end

  def do_rapidpro_sync?
    return false if Rails.application.credentials.rapidpro[:token].blank?

    cart.rapidpro_sync && cart.rapidpro_uuid.present?
  end
end
