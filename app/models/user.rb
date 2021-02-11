# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                      :integer          not null, primary key
#  email                   :string(255)      default(""), not null
#  encrypted_password      :string(255)      default(""), not null
#  reset_password_token    :string(255)
#  reset_password_sent_at  :datetime
#  remember_created_at     :datetime
#  sign_in_count           :integer          default(0)
#  current_sign_in_at      :datetime
#  last_sign_in_at         :datetime
#  current_sign_in_ip      :string(255)
#  last_sign_in_ip         :string(255)
#  password_salt           :string(255)
#  invitation_token        :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  approved                :boolean          default(FALSE), not null
#  name                    :string(255)
#  token                   :string(255)
#  phone_number            :string(255)
#  new_person_notification :boolean          default(FALSE)
#  team_id                 :bigint(8)
#  invitation_created_at   :datetime
#  invitation_sent_at      :datetime
#  invitation_accepted_at  :datetime
#  invitation_limit        :integer
#  invited_by_type         :string(255)
#  invited_by_id           :bigint(8)
#  invitations_count       :integer          default(0)
#

# TODO: (EL) rename new_person_notification to something like is_admin

class User < ApplicationRecord
  has_paper_trail ignore: [:last_sign_in_at]
  # acts_as_tagger #if we want owned tags.

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :zxcvbnable, # password strength
         stretches: Rails.env.production? ? 1 : 10

  has_many :research_sessions
  has_many :invitations, through: :research_sessions
  has_many :rewards
  has_many :carts_user
  has_many :carts, through: :carts_user
  belongs_to :team

  after_commit :create_cart, on: :create
  phony_normalize :phone_number, default_country_code: 'US'
  phony_normalized_method :phone_number, default_country_code: 'US'

  has_secure_token # for calendar feeds

  scope :upcoming_sessions, lambda { |d = 7|
    joins(:research_sessions).merge(ResearchSession.upcoming(d))
  }

  scope :approved, -> { where(approved: true) }
  scope :admin, -> { where(new_person_notification: true) }

  # for sanity's sake
  alias_attribute :email_address, :email
  alias_attribute :title, :name
  alias_attribute :full_name, :name

  def admin?
    new_person_notification
  end

  def approve!
    update(approved: true)
    Rails.logger.info(I18n.t('user.approved', email: email))
  end

  def unapprove!
    update(approved: false)
    Rails.logger.info(I18n.t('user.unapproved', email: email))
  end

  def rewards_total
    end_of_last_year = Time.zone.today.beginning_of_year - 1.day
    total = rewards.where('created_at > ?', end_of_last_year).sum(:amount_cents)
    Money.new(total, 'USD')
  end

  def unassigned_gift_cards_count
    GiftCard.unassigned.where(user_id: id).size
  end

  delegate :budget, to: :team

  def available_budget
    budget.amount # always in ruby money
  end

  def self.send_all_reminders
    # this is where reservation_reminders
    # called by sidekiq scheduler.
    User.upcoming_sessions(1).find_each(&:send_session_reminder)
  end

  def send_session_reminder
    sessions = research_sessions.upcoming(1).map(&:id)
    ::UserMailer.session_reminder(
      session_ids: sessions,
      user_id: id
    ).deliver_later
  end

  # todo, this needs work.
  # ActiveRecord::RecordNotSaved (You cannot call create unless the parent is saved)
  def create_cart(cart_name = nil, assign = true) # rubocop:todo Style/OptionalBooleanParameter
    cart_name = "#{name}-pool" if cart_name.nil?
    cart = Cart.create(name: cart_name, user_id: id)
    cart.save!
    cart.assign_current_cart(id) if assign # default assign
  end

  def current_cart
    CartsUser.find_by(user_id: id, current_cart: true).cart
  rescue NoMethodError => _e
    # this is used for users created before multi-cart.
    cart = Cart.find_by(user_id: id)
    cart.add_user(id)
    cart.assign_current_cart(id)
    cart.save
    cart
  end

  def current_cart=(cart) # this is tedious. could be better
    cart = Cart.find cart if cart.class.to_s != 'Cart'
    return if cart == current_cart

    cart_id = cart.id
    begin
      cu = CartsUser.find_by(user_id: id, cart_id: cart_id)
      CartsUser.where(user_id: id).update_all(current_cart: false)
      cu.current_cart = true
      cu.save
    rescue NoMethodError => _e
      cart = Cart.find cart_id
      cart.add_user(id)
      cart.assign_current_cart(id)
      cart.save
    end
  end

  def weak_words
    ['patterns', Rails.application.credentials.site[:name], name, email]
  end
end
