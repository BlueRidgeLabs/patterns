# frozen_string_literal: true

# == Schema Information
#
# Table name: people
#
#  id                               :integer          not null, primary key
#  first_name                       :string(255)
#  last_name                        :string(255)
#  email_address                    :string(255)
#  address_1                        :string(255)
#  address_2                        :string(255)
#  city                             :string(255)
#  state                            :string(255)
#  postal_code                      :string(255)
#  geography_id                     :integer
#  primary_device_id                :integer
#  primary_device_description       :string(255)
#  secondary_device_id              :integer
#  secondary_device_description     :string(255)
#  primary_connection_id            :integer
#  primary_connection_description   :string(255)
#  phone_number                     :string(255)
#  participation_type               :string(255)
#  created_at                       :datetime
#  updated_at                       :datetime
#  signup_ip                        :string(255)
#  signup_at                        :datetime
#  voted                            :string(255)
#  called_311                       :string(255)
#  secondary_connection_id          :integer
#  secondary_connection_description :string(255)
#  verified                         :string(255)
#  preferred_contact_method         :string(255)
#  token                            :string(255)
#  active                           :boolean          default(TRUE)
#  deactivated_at                   :datetime
#  deactivated_method               :string(255)
#  neighborhood                     :string(255)
#  referred_by                      :string(255)
#  low_income                       :boolean
#  rapidpro_uuid                    :string(255)
#  landline                         :string(255)
#  created_by                       :integer
#  screening_status                 :string(255)      default("new")
#  phone_confirmed                  :boolean          default(FALSE)
#  email_confirmed                  :boolean          default(FALSE)
#  confirmation_sent                :boolean          default(FALSE)
#  welcome_sent                     :boolean          default(FALSE)
#  participation_level              :string(255)      default("new")
#  locale                           :string(255)      default("en")
#  cached_tag_list                  :text(65535)
#

# FIXME: Refactor and re-enable cop
# rubocop:disable ClassLength
class Person < ApplicationRecord
  has_paper_trail

  acts_as_taggable

  VERIFIED_TYPES = [
    VERIFIED_TYPE = 'Verified',
    NOT_VERIFIED_TYPE = 'No'
  ].freeze

  # * Active DIG member =“Participated in 3+ sessions” = invited to join FB group;
  # * [Need another name for level 2] = “Participated in at least one season--
  #     (could code as 6 months active) OR at least 2 different projects/teams
  #     (could code based on being tagged in a session by at least 2 different teams)
  # * DIG Ambassador = “active for at least one year, 2+ projects/teams
  # if there’s any way to automate that info to flow into dashboard/pool —
  # and notify me when new person gets added-- that would be amazing
  PARTICIPATION_LEVELS = [
    PARTICIPATION_LEVEL_NEW = "new",
    PARTICIPATION_LEVEL_INACTIVE = "inactive",
    PARTICIPATION_LEVEL_PARTICIPANT = "participant",
    PARTICIPATION_LEVEL_ACTIVE = "active",
    PARTICIPATION_LEVEL_AMBASSADOR = "ambassador"
  ]

  page 50

  # include Searchable
  include ExternalDataMappings
  include Neighborhoods

  phony_normalize :phone_number, default_country_code: 'US'
  phony_normalized_method :phone_number, default_country_code: 'US'

  has_many :comments, as: :commentable, dependent: :destroy

  has_many :rewards
  accepts_nested_attributes_for :rewards, reject_if: :all_blank
  attr_accessor :rewards_attributes

  has_many :invitations
  has_many :research_sessions, through: :invitations

  # TODO: remove people from carts on deactivation
  has_many :carts_people
  has_many :carts, through: :carts_people, foreign_key: :person_id

  has_secure_token :token

  if ENV['RAILS_ENV'] == 'production'
    after_commit :send_to_mailchimp, on: %i[update create] if ENV['MAILCHIMP_API_KEY']

    after_commit :update_rapidpro, on: %i[update create] if ENV['RAPIDPRO_TOKEN']
    before_destroy :delete_from_rapidpro if ENV['RAPIDPRO_TOKEN']
  end

  after_create  :update_neighborhood
  after_commit  :send_new_person_notifications, on: :create

  validates :first_name, presence: true
  validates :last_name, presence: true

  validates :postal_code, presence: true
  validates :postal_code, zipcode: { country_code: :us }

  # phony validations and normalization
  phony_normalize :phone_number, default_country_code: 'US'
  phony_normalize :landline, default_country_code: 'US'

  validates :phone_number, presence: true, length: { in: 9..15 },
    unless: proc { |person| person.email_address.present? }
  validates :email_address, presence: true,
    unless: proc { |person| person.phone_number.present? }

  validates :email_address,
    format: { with: Devise.email_regexp,
              if: proc { |person| person.email_address.present? } }

  validates :phone_number, allow_blank: true, uniqueness: true
  validates :landline, allow_blank: true, uniqueness: true

  validates :email_address, email: true, allow_blank: true, uniqueness: true

  # scope :no_signup_card, -> { where('id NOT IN (SELECT DISTINCT(person_id) FROM rewards where rewards.reason = 1)') }
  # scope :signup_card_needed, -> { joins(:rewards).where('rewards.reason !=1') }

  scope :verified, -> { where('verified like ?', '%Verified%') }
  scope :not_verified, -> { where.not('verified like ?', '%Verified%') }
  scope :active, -> { where(active: true) }
  scope :deactivated, -> { where(active: false) }

  scope :order_by_reward_sum, -> { joins(:rewards).includes(:research_sessions).where('rewards.created_at >= ?', Time.current.beginning_of_year).select('people.id, people.first_name,people.last_name, people.active,sum(rewards.amount_cents) as total_rewards').group('people.id').order('total_rewards desc') }
  # no longer using this. now managing active elsewhere
  # default_scope { where(active:

  ransacker :full_name, formatter: proc { |v| v.mb_chars.downcase.to_s } do |parent|
    Arel::Nodes::NamedFunction.new('lower',
      [Arel::Nodes::NamedFunction.new('concat_ws',
        [Arel::Nodes.build_quoted(' '), parent.table[:first_name], parent.table[:last_name]])])
  end

  scope :ransack_tagged_with, ->(*tags) { tagged_with(tags) }

  def self.ransackable_scopes(_auth_object = nil)
    %i[no_signup_card ransack_tagged_with]
  end

  # TODO:
  def self.locale_name_to_locale(locale_name)
    obj = { 'english': 'en', 'spanish': 'es', 'chinese': 'zh' }
    obj[locale_name.downcase]
  end

  ransack_alias :comments, :comments_content
  ransack_alias :nav_bar_search, :full_name_or_email_address_or_phone_number_or_comments_content

  # def self.send_all_reminders
  #   # this is where reservation_reminders
  #   # called by whenever in /config/schedule.rb
  #   Person.active.all.find_each(&:send_invitation_reminder)
  # end

  def self.update_all_participation_levels
    @results = []
    Person.active.all.find_each do |person|
      @results << person.update_participation_level
    end
    @results.compact!
    if @results.present?
      User.approved.admin.all.find_each do |u|
        AdminMailer.participation_level_change(results: @results, to: u.email_address).deliver_later
      end
    end
  end

  def inactive_criteria
    # have gotten a gift card, but not in the past year.
    rewards.where('created_at < ?', 1.year.ago).size >= 1
  end

  def participant_criteria
    # gotten a gift card in the past year.
    rewards.where('created_at > ?', 1.year.ago).map { |g| g&.research_session&.id }.compact.uniq.size >= 1
  end

  def active_criteria
    # gotten a gift card for a research session in the past 6 months
    # and two teams
    rewards.where('created_at > ?', 6.months.ago).map { |g| g&.research_session&.id }.compact.uniq.size >= 1 || rewards.where('created_at > ?', 6.months.ago).map(&:team).uniq.size >= 2
  end

  def ambassador_criteria
    # older than a year and 2 or more sessions with two teams and
    # either 3 research sessions or 6 cards in the last year
    if tag_list.include?('brl special ambassador')
      true
    else
      rewards.where('created_at > ?', 1.year.ago).map(&:team).uniq.size >= 2 && rewards.map { |g| g&.research_session&.id }.compact.uniq.size >= 3
    end
  end

  def calc_participation_level
    pl = PARTICIPATION_LEVEL_NEW # needs outreach
    pl = PARTICIPATION_LEVEL_INACTIVE    if inactive_criteria
    pl = PARTICIPATION_LEVEL_PARTICIPANT if participant_criteria
    pl = PARTICIPATION_LEVEL_ACTIVE      if active_criteria
    pl = PARTICIPATION_LEVEL_AMBASSADOR  if ambassador_criteria
    pl
  end

  def update_participation_level
    return if tag_list.include? 'not dig'

    new_level = calc_participation_level

    if participation_level != new_level
      old_level = participation_level
      self.participation_level = new_level

      tag_list.remove(old_level)
      tag_list.add(new_level)
      save
      Cart.where(name: Person::PARTICIPATION_LEVELS).find_each do |cart|
        if cart.name == new_level
          begin
            cart.people << self
          rescue StandardError
            ActiveRecord::RecordInvalid
          end
        else
          cart.remove_person(id) # no-op if person not in cart
        end
      end # end cart update
      return { pid: id, old: old_level, new: new_level }
    end
  end

  def signup_gc_sent
    signup_cards = rewards.where(reason: 1)
    return true unless signup_cards.empty?

    false
  end

  def verified?
    verified&.start_with?('Verified')
  end

  def rewards_total
    end_of_last_year = Time.zone.today.beginning_of_year - 1.day
    total = rewards.where('created_at > ?', end_of_last_year).sum(:amount_cents)
    Money.new(total, 'USD')
  end

  def rewards_count
    rewards.size
  end

  def tag_values
    tags.collect(&:name)
  end

  def tag_count
    tag_list.size
  end

  def screened?
    tag_list.include?('screened')
  end

  def send_to_mailchimp
    status = active? ? 'subscribed' : 'unsubscribed'
    MailchimpUpdateJob.perform_async(id, status)
  end

  def delete_from_rapidpro
    RapidproDeleteJob.perform_async(id)
  end

  def update_rapidpro
    if active && !tag_list.include?('not dig')
      RapidproUpdateJob.perform_async(id)
    elsif !active || tag_list.include?('not dig')
      delete_from_rapidpro
    end
  end

  def primary_device_type_name
    Patterns::Application.config.device_mappings.rassoc(primary_device_id)[0].to_s if primary_device_id.present?
  end

  def secondary_device_type_name
    Patterns::Application.config.device_mappings.rassoc(secondary_device_id)[0].to_s if secondary_device_id.present?
  end

  def primary_connection_type_name
    Patterns::Application.config.connection_mappings.rassoc(primary_connection_id)[0].to_s if primary_connection_id.present?
  end

  def secondary_connection_type_name
    Patterns::Application.config.connection_mappings.rassoc(secondary_connection_id)[0].to_s if secondary_connection_id.present?
  end

  def lat_long
    ::ZIP_LAT_LONG[postal_code.to_s]
  end

  def full_name
    [first_name, last_name].join(' ')
  end

  def address_fields_to_sentence
    [address_1, address_2, city, state, postal_code].reject(&:blank?).join(', ')
  end

  # def send_invitation_reminder
  #   # called by whenever in /config/schedule.rb
  #   invs = invitations.remindable.upcoming(2)
  #   case preferred_contact_method.upcase
  #   when 'SMS'
  #     ::InvitationReminderSms.new(to: person, invitations: invs).send
  #   when 'EMAIL'
  #     ::PersonMailer.remind(
  #       invitations:  invs,
  #       email_address: email_address
  #     ).deliver_later
  #   end

  #   invs.each do |inv|
  #     if inv.aasm_state == 'invited'
  #       inv.aasm_state = 'reminded'
  #       inv.save
  #     end
  #   end
  # end

  def to_a
    fields = Person.column_names
    fields.push('tags')
    fields.map do |f|
      field_value = send(f.to_sym)
      if f == 'phone_number'
        if field_value.present?
          field_value.phony_formatted(format: :national, spaces: '-')
        else
          ''
        end
      elsif f == 'email_address'
        field_value.presence || ''
      elsif f == 'tags'
        tag_values.present? ? tag_values.join('|') : ''
      else
        field_value
      end
    end
  end

  def deactivate!(type = nil)
    self.active = false
    self.deactivated_at = Time.current
    self.deactivated_method = type if type

    save! # sends background mailchimp update
    delete_from_rapidpro # remove from rapidpro
  end

  def reactivate!
    self.active = true
    save!
    update_rapidpro
  end

  def md5_email
    Digest::MD5.hexdigest(email_address.downcase) if email_address.present?
  end

  def update_neighborhood
    n = zip_to_neighborhood(postal_code)
    self.signup_at = created_at if signup_at.nil?
    if n.present?
      self.neighborhood = n
      save
    end
  end

  def send_new_person_notifications
    User.where(new_person_notification: true).find_each do |user|
      email = user.email_address
      ::UserMailer.new_person_notify(email_address: email, person: self).deliver_later
    end
  end
end
# rubocop:enable ClassLength
