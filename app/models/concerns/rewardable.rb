# frozen_string_literal: true

require 'active_support/concern'

module Rewardable
  # a rewardable object can be assigned and unassigned.
  # has an amount_cents and amount_denomination
  # has a created_by
  # has a user_id

  extend ActiveSupport::Concern

  included do
    has_paper_trail
    validates :reward_id, uniqueness: true, allow_nil: true
    monetize :amount_cents
    has_one :reward, as: :rewardable, dependent: :nullify
    belongs_to :user
    belongs_to :person, optional: true
    default_scope { includes(:reward) }
    scope :unassigned, -> { where(reward_id: nil) }
    scope :assigned, -> { where.not(reward_id: nil) }
  end

  # may not be necessary because of dependent :nullify
  def unassign
    self.reward_id = nil
    save
  end

  def assign(reward_id)
    return false if reward_id.nil?

    if self.reward_id.present?
      errors.add(:base, "This #{self.class.downcase} has already been assigned")
      raise ActiveRecord::RecordInvalid.new(self)
    else
      self.reward_id = reward_id
      save
    end
  end

  def total_for_budget
    if respond_to?(:fee)
      amount + fee
    else
      amount
    end
  end
end
