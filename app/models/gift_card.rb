# frozen_string_literal: true

# == Schema Information
#
# Table name: gift_cards
#
#  id               :bigint(8)        not null, primary key
#  full_card_number :string(255)
#  expiration_date  :string(255)
#  sequence_number  :integer
#  secure_code      :string(255)
#  batch_id         :string(255)
#  status           :string(255)      default("created")
#  user_id          :integer
#  reward_id        :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  amount_cents     :integer          default(0), not null
#  amount_currency  :string(255)      default("USD"), not null
#  created_by       :integer
#

# records card details for activation and check calls
class GiftCard < ApplicationRecord
  include AASM
  include Rewardable

  page 20

  attr_accessor :old_user_id

  has_many :activation_calls, dependent: :destroy
  alias_attribute :calls, :activation_calls

  validate :luhn_number_valid
  validates :expiration_date, presence: true
  validates :batch_id, presence: true
  validates :sequence_number, presence: true
  validates :expiration_date, presence: true
  validates :user_id, presence: true

  validates :expiration_date,
            format: { with: %r{\A(0|1)([0-9])\/([0-9]{2})\z}i }

  validates :batch_id, format: { with: /\A[0-9]*\z/ }
  validates :secure_code, format: { with: /\A[0-9]*\z/ }, allow_blank: true

  # sequences are per batch
  validates :sequence_number, uniqueness: { scope: :batch_id }

  default_scope { order(sequence_number: :asc) }

  scope :preloaded, lambda {
                      where(full_card_number: [nil, ''],
                            secure_code: [nil, ''],
                            status: 'preload')
                    }

  scope :ready, -> { where.not(status: ['preload']) }
  # see force_immutable below. do we not want to allow people to
  # change the assigned activation to gift card? unclear
  # IMMUTABLE = %w{gift_card_id}
  # validate :force_immutable

  before_save :scrub_input
  before_save :set_created_by

  # starts activation call process on create after commit happens
  # after_commit :create_activation_call, on: :create

  # uses action cable to update card.
  after_commit :update_front_end, on: %i[update create]

  def self.import(file, user)
    errored_cards = []
    xls =  Roo::Spreadsheet.open(file)
    cols = { full_card_number: 'full_card_number', expiration_date: 'expiration_date', amount: 'amount', sequence_number: 'sequence_number', secure_code: 'secure_code', batch_id: 'batch_id' }
    xls.sheet(0).each(cols) do |row|
      if row[:full_card_number].blank? || row[:full_card_number] == 'full_card_number'
        next
      end # empty rows
      if GiftCard.where(sequence_number: row[:sequence_number], batch_id: row[:batch_id]).present?
        next
      end

      row[:full_card_number].delete!('-')

      ca = GiftCard.new(row)
      ca.user_id = user.id
      ca.created_by = user.id
      # results is an array of errored card activatoins
      if ca.valid?
        ca.save
        ca.start_activate!
      else
        err_msg = "Card Error: sequence: #{ca.sequence_number}, #{ca.full_card_number}, #{ca.errors[:base]}"
        Airbrake.notify(err_msg)
        logger.info(err_msg)
        errored_cards << ca
      end
    end
    errored_cards
  end

  def self.active_unassigned_count(current_user)
    current_user.admin? ? GiftCard.active.unassigned.size : GiftCard.active.unassigned.where(user_id: current_user.id).size
  end

  aasm column: 'status', requires_lock: true do
    state :preload, initial: true
    state :ready_to_activate
    state :activate_started
    state :activate_errored
    state :check_started
    state :check_errored
    state :active

    event :return_to_preloaded do
      transitions to: :preload
    end

    event :ready, guards: :can_activate? do
      transitions from: :preload, to: :ready_to_activate
    end

    event :start_activate, after_commit: :create_activation_call do
      transitions from: %i[ready_to_activate activate_started], to: :activate_started
    end

    event :activate_error, after_commit: :activation_error_report do
      transitions from: %i[activate_started activate_errored], to: :activate_errored
    end

    event :start_check, after_commit: :create_check_call do
      transitions from: %i[activate_errored check_errored active],
                  to: :check_started
    end

    # after_commit here because we want to ensure that
    # the history is present
    event :check_error, after_commit: :create_check_call do
      transitions from: %i[activate_started check_started activate_errored active check_errored], to: :check_errored
    end

    event :success, after_commit: :do_success_notification do
      transitions to: :active
    end
  end

  def create_activation_call
    ActivationCall.create(gift_card_id: id, call_type: 'activate')
  end

  # override allows manual check calls
  def create_check_call(override: false)
    if override || activation_calls.where(call_type: 'check').size < 5
      ActivationCall.create(gift_card_id: id, call_type: 'check')
    end
  end

  def do_success_notification
    # action cable update to front end.
    true
  end

  def activation_error_report
    # transition into start check
    start_check
  end

  # almost always backend
  def update_front_end
    # if assigned, delete.
    # otherwise, update
    if reward_id.nil?
      User.admin.each { |u| broadcast_update(u) }
      broadcast_update
    else
      User.admin.each { |u| broadcast_delete(u) }
      broadcast_delete
    end
  end

  def last_4
    full_card_number.to_s.last(4)
  end

  def permitted_states
    aasm.states(permitted: true).map(&:name).map(&:to_s)
  end

  def sort_helper
    case status
    when 'active'
      id.to_i
    when 'activate_started'
      -6
    when 'check_started'
      -7
    when 'ready'
      -8
    when 'activate_errored'
      -9
    when 'check_errored'
      -10
    when 'preload'
      -12
    else
      -13
    end
  end

  def label
    case status
    when 'active'
      'success'
    when 'activate_started'
      'warning'
    when 'check_started'
      'warning'
    when 'preload'
      'warning'
    when 'ready_to_activate'
      'success'
    when 'activate_errored'
      'important'
    when 'check_errored'
      'important'
    end
  end

  def update_balance
    create_check_call(override: true)
  end

  def ongoing_call?
    return false if active? # there may be, but we don't care.

    calls.ongoing.size.positive?
  end

  def can_run_check?
    return false if active? # don't run any more checks if active
    return false if preload?
    return false if ready_to_activate?

    !active? && !ongoing_call?
  end

  def scrub_input
    self.sequence_number = sequence_number&.to_i
    self.batch_id = batch_id&.to_i
    self.full_card_number = full_card_number&.delete('-')
    self.secure_code = secure_code&.delete('.0', '')
    if secure_code.present?
      # sometimes we drop leading 0's in csv
      secure_code.prepend('0') while secure_code.length < 3
    end
  end

  private

  def set_created_by
    self.created_by = user_id
  end

  def broadcast_update(c_user = nil)
    return if status == 'preload' # instead, we should manage this

    current_user = c_user.nil? ? user : c_user
    ActionCable.server.broadcast "gift_card_event_#{current_user.id}_channel",
                                 type: :update,
                                 status: status,
                                 id: id,
                                 large: render_large_gift_card(current_user),
                                 mini: render_mini_gift_card(current_user),
                                 count: GiftCard.active_unassigned_count(current_user)
  end

  def broadcast_delete(c_user = nil)
    current_user = c_user.nil? ? user : c_user
    ActionCable.server.broadcast "gift_card_event_#{current_user.id}_channel",
                                 status: status,
                                 type: :delete,
                                 id: id,
                                 count: GiftCard.active_unassigned_count(current_user)
  end

  def render_large_gift_card(c_user = nil)
    current_user = c_user.nil? ? user : c_user
    ApplicationController.render partial: 'gift_cards/single_gift_card',
                                 locals: { gift_card: self, current_user: current_user, approved_users: User.approved.all }
  end

  def render_mini_gift_card(c_user = nil)
    current_user = c_user.nil? ? user : c_user
    ApplicationController.render partial: 'gift_cards/gift_card_mini',
                                 locals: { gift_card: self, current_user: current_user }
  end

  def luhn_number_valid
    return true if full_card_number.blank?

    if full_card_number.length != 16
      errors[:base].push('Card Number is not long enough.')
      end
    unless CreditCardValidations::Luhn.valid?(full_card_number)
      errors[:base].push("Card number #{full_card_number} is not valid.")
      end
  end

  def can_activate?
    return false if full_card_number.blank?
    return false if secure_code.blank?
    return false unless CreditCardValidations::Luhn.valid?(full_card_number)

    true
  end

  # gift_card_id can't change one set.
  # dunno if we really want it.
  # def force_immutable
  #   if persisted?
  #     IMMUTABLE.each do |attr|
  #       next if self[attr].nil? # allow updates to nil

  #       changed.include?(attr) &&
  #         errors.add(attr, :immutable) &&
  #         self[attr] = changed_attributes[attr]
  #     end
  #   end
  # end
end
