# frozen_string_literal: true

# == Schema Information
#
# Table name: carts_users
#
#  cart_id      :bigint(8)        not null
#  user_id      :bigint(8)        not null
#  current_cart :boolean          default(FALSE)
#  id           :bigint(8)        not null, primary key
#

class CartsUser < ApplicationRecord
  belongs_to :cart
  belongs_to :user

  validates :user_id,
            uniqueness: { scope: :cart_id,
                          message: "can only have a cart one time." }
  validates :current_cart,
            uniqueness: { scope: :user_id, message: "only one current cart possible" },
            if: proc { |p| p.current_cart == true }

  def set_current_cart
    # update all is OK, because d
    CartsUser.where(user_id: user_id).update_all(current_cart: false)
    current_cart = true
  end
end
