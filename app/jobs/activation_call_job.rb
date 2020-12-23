# frozen_string_literal: true

class ActivationCallJob
  include Sidekiq::Worker
  sidekiq_options retry: 5

  # how it works: sends a twilio call, and records the sid, etc in the call object
  def perform(id)
    Rails.logger.info '[ActivationCall] job enqueued'
    call = ActivationCall.find(id)

    case call.call_type # activation or check for now. soon balance.
    when 'activate'
      url = "https://#{HOSTNAME}/activation_calls/activate/#{call.token}.xml"
    when 'check'
      url = "https://#{HOSTNAME}/activation_calls/check/#{call.token}.xml"
    end
    twilio = Twilio::REST::Client.new
    res = twilio.api.account.calls.create(
      from: Rails.application.credentials.twilio[:signup_number], # From your Twilio number
      to: '+18663008288', # BOA activation number
      # Fetch instructions from this URL when the call connects
      url: url,
      method: 'GET'
    )
    call.call_status = 'started'
    call.sid = res.sid
    call.save!
    # start background status check
    ActivationCallUpdateJob.perform_in(1.minute, id)
  end
end
