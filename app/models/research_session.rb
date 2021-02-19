# frozen_string_literal: true

#
# == Schema Information
#
# Table name: research_sessions
#
#  id              :integer          not null, primary key
#  description     :text(65535)
#  buffer          :integer          default(0), not null
#  created_at      :datetime
#  updated_at      :datetime
#  user_id         :integer
#  title           :string(255)
#  start_datetime  :datetime
#  end_datetime    :datetime
#  sms_description :string(255)
#  session_type    :integer          default(1)
#  location        :string(255)
#  duration        :integer          default(60)
#  cached_tag_list :string(255)
#

class ResearchSession < ApplicationRecord
  has_paper_trail
  acts_as_taggable # new, better tagging system
  include Calendarable
  attr_accessor :people_ids

  DURATION_OPTIONS = [15, 30, 45, 60, 75, 90, 115, 120, 135].freeze

  self.per_page = 50

  # different types # breaks stuff
  #  enum session_type: %i[interview focus_group social test]

  belongs_to :user
  has_many :invitations
  # has_many :rewards, through: :invitations
  has_many :people, through: :invitations
  has_many :comments, as: :commentable, dependent: :destroy
  before_create :update_missing_attributes
  
  after_save :update_frontend

  accepts_nested_attributes_for :invitations, reject_if: :all_blank, allow_destroy: true

  validate :clean_invitations

  validates :description,
            :title,
            :start_datetime,
            :duration,
            :user_id,
            presence: true

  validates :duration, numericality: { greater_than_or_equal_to: 0 }

  default_scope { includes(:invitations).order(start_datetime: :desc) }

  scope :today, -> { where(start_datetime: Time.zone.today.beginning_of_day..Time.zone.today.end_of_day) }

  scope :future, lambda {
    where('start_datetime > ?',
          Time.zone.today.end_of_day)
  }
  scope :past, lambda {
    where('start_datetime < ?',
          Time.zone.today.beginning_of_day)
  }

  scope :upcoming, ->(d = 7) { where(start_datetime: Time.zone.today.beginning_of_day..Time.zone.today.end_of_day + d.days) }

  scope :ransack_tagged_with, ->(*tags) { tagged_with(tags) }

  ransack_alias :comments, :comments_content

  ransack_alias :omni_search, :title_or_description_or_people_name_or_comments_content_or_people_phone_number_or_people_email_address

  def self.ransackable_scopes(_auth = nil)
    %i[ransack_tagged_with]
  end

  def people_name_and_id
    people.map do |i|
      { id: i.id,
        name: i.full_name,
        label: i.full_name,
        value: i.id }
    end
  end

  def all_invitees_marked
    return true unless can_reward?

    marked = invitations.count { |i| i.attended? || i.missed? }
    marked == invitations.size
  end

  def rewards_needed_to_complete
    attended = invitations.attended.size
    if attended.positive?
      attended - invitations.count { |i| i.rewards.size >= 1 }
    else
      0
    end
  end

  def consent_forms_needed_to_complete
    attended = invitations.attended.size
    if attended.positive?
      attended - invitations.attended.count { |i| i.person.consent_form.present?} 
    else
      0
    end
  end

  def complete?
    return true if invitations.size.zero? && can_reward? #empty and in past

    # is everyone all set? this is expensive.
    rewards_needed_to_complete.zero? && consent_forms_needed_to_complete.zero? && can_reward? && all_invitees_marked
  end

  def can_survey?
    tag_list.include? 'survey'
  end

  def can_reward?
    start_datetime < Time.zone.now
  end

  def is_invited?(person)
    invitations.find_by(person_id: person.id).present?
  end

  def rewards
    invitations.map(&:rewards).flatten
  end

  # this should happen in a background job.
  def update_frontend
    # set status to complete = true OR complete = false
    # call actioncable to render some partials. research_session/record
    # call actioncable to update the "todos" section of research_session/show
    # should be called everytime:
    # * invitation is updated
    # * person.consent_form attached. (this we'll have to think about)
  end


  private

  def update_missing_attributes
    self.end_datetime = start_datetime + duration.minutes if end_datetime.nil?
  end

  def clean_invitations
    invitations.each { |inv| inv.delete unless inv.valid? }
  end
end
