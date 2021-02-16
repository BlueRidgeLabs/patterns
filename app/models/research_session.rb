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

  def can_survey?
    tag_list.include? 'survey'
  end

  def can_reward?
    start_datetime < Time.zone.now
  end

  def is_invited?(person)
    invitations.pluck(:person_id).include? person.id
  end

  def rewards
    invitations.map(&:rewards).flatten
  end

  def send_invitation_notifications
    invitations.where(aasm_state: 'created').find_each(&:invite!)
  end

  private

  def update_missing_attributes
    self.end_datetime = start_datetime + duration.minutes if end_datetime.nil?
  end

  def clean_invitations
    invitations.each { |inv| inv.delete unless inv.valid? }
  end
end
