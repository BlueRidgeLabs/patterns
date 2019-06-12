# frozen_string_literal: true

# == Schema Information
#
# Table name: activation_calls
#
#  id           :bigint(8)        not null, primary key
#  gift_card_id :integer
#  sid          :string(255)
#  transcript   :text(16777215)
#  audio_url    :string(255)
#  call_type    :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  call_status  :string(255)      default("created")
#  token        :string(255)
#

class ActivationCall < ApplicationRecord
  has_paper_trail
  has_secure_token

  CALL_TYPES = [
    CALL_TYPE_ACTIVATE = 'activate',
    CALL_TYPE_CHECK = 'check'
    # CALL_TYPE_BALANCE = 'balance' # balance soon
  ].freeze

  CALL_STATUS_STARTED = 'started'

  validates :gift_card_id, presence: true
  validates :call_type, presence: true
  validates :call_type, inclusion: { in: CALL_TYPES }

  belongs_to :gift_card
  after_commit :enqueue_call, on: :create
  after_commit :update_front_end

  alias_attribute :card, :gift_card

  scope :ongoing, -> { where(call_status: CALL_STATUS_STARTED) }
  scope :checks, -> { where(call_type: CALL_TYPE_CHECK) }
  scope :activations, -> { where(call_type: CALL_TYPE_ACTIVATE) }

  after_initialize :create_twilio

  def transcript_check
    # this will be very different.
    # needs more subtle checks for transcription errors. pehaps distance?
    return false if transcript.nil?

    transcript.downcase.include? type_transcript
  end

  def type_transcript
    case call_type
    when CALL_TYPE_ACTIVATE
      I18n.t('activation_call.transcript.activate')
    when CALL_TYPE_CHECK
      I18n.t('activation_call.transcript.check')
      # when 'balance' # not yet implemented. but could be
      #   'the available balance'
    end
  end

  def can_be_updated?
    call_status == 'started'
  end

  def balance
    if transcript.present? && call_type == 'check'
      regex = Regexp.new('\$\ ?[+-]?[0-9]{1,3}(?:,?[0-9])*(?:\.[0-9]{1,2})?')
      transcript.scan(regex)[0]&.delete('$')&.to_money || gift_card.amount
    else
      gift_card.amount
    end
  end

  def call
    @call ||= sid.nil? ? nil : @twilio.api.account.calls(sid).fetch
  end

  def timeout_error?
    call.status == 'completed' && (Time.current - updated_at) > 1.minute && !%w[success failure].include?(call_status)
  end

  def success
    self.call_status = 'success'
    gift_card.success!
  end

  def failure
    self.call_status = 'failure'
    # some gift cards get deleted, hence check
    gift_card.send("#{call_type}_error!".to_sym) if gift_card.present?
  end

  def enqueue_call
    ActivationCallJob.perform_async(id)
  end

  delegate :update_front_end, to: :gift_card

  private

    def create_twilio
      @twilio = Twilio::REST::Client.new
    end
end
