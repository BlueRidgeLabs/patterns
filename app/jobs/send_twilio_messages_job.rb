# frozen_string_literal: true

# # frozen_string_literal: true

# # app/jobs/twilio/send_messages.rb
# #
# # module TwilioSender
# # Send twilio messages to a list of phone numbers
# #
# # FIXME: Refactor and re-enable cop
# #
class SendTwilioMessagesJob
  include Sidekiq::Worker
  sidekiq_options retry: 1

  #   # FIXME: Refactor and re-enable cop
  #   #
  #   def perform(messages, phone_numbers, smsCampaign)
  #     Rails.logger.info '[TwilioSender] job enqueued'
  #     # Instantiate a Twilio client
  #     @twilio ||= Twilio::REST::Client.new

  #     Rails.logger.info "[TwilioSender#perform] Send #{messages} to #{phone_numbers}"
  #     if phone_numbers.present?

  #       phone_numbers.uniq!
  #       Rails.logger.info "[TwilioSender#perform] Send #{messages} to unique numbers - #{phone_numbers}"
  #       phone_numbers.reject! { |e| e.to_s.blank? }
  #       Rails.logger.info "[TwilioSender#perform] Send #{messages} to real numbers - #{phone_numbers}"
  #     else
  #       Rails.logger.warn "[TwilioSender#perform] phone_numbers is nil - #{phone_numbers}"
  #     end
  #     phone_numbers.each do |phone_number|
  #       @person = Person.find_by(phone_number: phone_number)
  #       phone_number = phone_number.strip.gsub('+1', '').delete('-')
  #       messages.each do |message|
  #         if message.present?
  #           begin
  #             renderer = ERB.new(message)
  #             message = renderer.result(binding).strip

  #             @outgoing = TwilioMessage.new
  #             @outgoing.to = phone_number.gsub('+1', '').delete('-')
  #             @outgoing.body = message
  #             @outgoing.from = ENV['TWILIO_SURVEY_NUMBER'].gsub('+1', '').delete('-')
  #             @outgoing.wufoo_formid = smsCampaign
  #             @outgoing.direction = 'outgoing-survey'
  #             @outgoing.save

  #             phone_number = '+1' + phone_number.strip.gsub('+1', '').delete('-')

  #             # Create and send an SMS message
  #             @message = client.account.messages.create(
  #               from: ENV['TWILIO_SURVEY_NUMBER'],
  #               to: phone_number,
  #               body: message
  #             )
  #             @outgoing.message_sid = @message.sid
  #             @outgoing.save
  #             Rails.logger.info("[Twilio][SendTwilioMessagesJob] #{phone_number}")
  #           rescue Twilio::REST::RequestError => e
  #             @outgoing.error_message = e.message
  #             @outgoing.save
  #             Rails.logger.warn("[Twilio][SendTwilioMessagesJob] had a problem. Full error: #{@outgoing.error_message}")
  #           end
  #         end
  #         sleep(1) # for twilio rate limiting, I presume.
  #       end
  #     end
  #   end
  #   # rubocop:enable
end
