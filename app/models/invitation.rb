# frozen_string_literal: true

# == Schema Information
#
# Table name: invitations
#
#  id                  :integer          not null, primary key
#  person_id           :integer
#  created_at          :datetime
#  updated_at          :datetime
#  research_session_id :integer
#  aasm_state          :string(255)
#

# FIXME: Refactor and re-enable cop
class Invitation < ApplicationRecord
  has_paper_trail

  include AASM
  include Calendarable

  belongs_to :person
  belongs_to :research_session
  validates :person, presence: true
  default_scope { includes(:person, :rewards) }
  # so users can take notes.
  has_many :comments, as: :commentable, dependent: :destroy

  # can't destroy an attended or rewarded invitation
  before_destroy :can_destroy?
  # this is how we give rewards for sessions.
  has_many :rewards, as: :giftable, dependent: :destroy

  # for frontend updating
  after_save :research_session_update

  # one person can't have multiple invitations for the same event
  validates :person_id, uniqueness: { scope: :research_session_id }

  # not sure about all these delegations.
  delegate :user,
           :start_datetime,
           :end_datetime,
           :title,
           :description,
           :location,
           :sms_description,
           :duration, to: :research_session

  scope :today, lambda {
    joins(:research_session)
      .where(research_sessions: { start_datetime: Time.zone.today.beginning_of_day..Time.zone.today.end_of_day })
  }

  scope :future, lambda {
    joins(:research_session)
      .where('research_sessions.start_datetime > ?',
             Time.zone.today.end_of_day)
  }

  scope :past, lambda {
    joins(:research_session)
      .where('research_sessions.start_datetime < ?',
             Time.zone.today.beginning_of_day)
  }

  scope :upcoming, lambda { |d = 7|
    joins(:research_session)
      .where(research_sessions: { start_datetime: Time.zone.today.beginning_of_day..Time.zone.today.end_of_day + d.days })
  }

  scope :remindable, lambda {
    where(aasm_state: %w[invited reminded confirmed])
  }

  scope :confirmable, lambda {
    where.not(aasm_state: %w[attended
                             cancelled
                             created
                             missed])
  }
  # invitations can move through states
  # necessary for text messaging bits in the future
  # TODO: (EL) uncomment after_commits, and test
  aasm do
    state :created, initial: true
    state :invited
    state :reminded
    state :confirmed
    state :cancelled # means that they cancelled ahead of time
    state :missed # means they didn't cancel
    state :attended

    event :invite, guard: :in_future? do
      # after_commit: :send_invitation,
      transitions from: :created, to: :invited
    end

    event :remind, guard: :in_future? do
      # after_commit: :send_reminder,
      transitions from: %i[invited reminded], to: :reminded
    end

    event :confirm, guard: :in_future? do
      # after_commit: :notify_about_confirmation,
      transitions from: %i[invited reminded], to: :confirmed
    end

    event :cancel, guard: :in_future? do
      # after_commit: :notify_about_cancellation,
      transitions from: %i[invited cancel reminded confirmed], to: :cancelled
    end

    event :attend, guard: :can_attend? do
      # can transition from anything to attended.
      transitions to: :attended
    end

    event :miss, guard: :can_miss? do
      # should this be able to transition from "attended" ?
      transitions from: %i[created invited reminded confirmed], to: :missed

      error do |_e|
        if rewards.empty?
          errors.add(:base, "Can't set to miss with rewards. Delete them first?")
        elsif in_past?
          errors.add(:base, "Event isn't in the past. Maybe delete invitation?")
        end
      end
    end
  end

  def research_session_update
    research_session.update_frontend
  end

  def owner_or_invitee?(person_or_user)
    # both people and users can own a invitation.
    return true if user == person_or_user
    return true if person == person_or_user
    return false if person_or_user.nil?

    false
  end

  def permitted_events
    aasm.events.call(permitted: true).map(&:name).map(&:to_s)
  end

  def permitted_states
    aasm.states(permitted: true).map(&:name).map(&:to_s)
  end

  def state_action_array
    permitted_events.each_with_index.map do |e, i|
      [permitted_states[i], e]
    end
  end

  def complete?
    (in_past? && attended? && rewards.size.positive? && person.consent_form.present?) || (in_past? && missed?)
  end

  def completion_tasks; end

  def can_destroy?
    throw(:abort) unless rewards.empty? && %w[attended missed].exclude?(aasm_state)
  end

  def can_attend?
    in_past? && !attended?
  end

  def can_miss?
    in_past? && rewards.empty?
  end

  def in_future?
    Time.zone.now < start_datetime
  end

  def in_past?
    Time.zone.now > start_datetime
  end
end
