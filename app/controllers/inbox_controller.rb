# frozen_string_literal: true

# handles emails sent to our inbox. essentially forwards to admins
class InboxController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  include Mandrill::Rails::WebHookProcessor

  # To completely ignore unhandled events (not even logging), uncomment this line
  ignore_unhandled_events!

  # If you want unhandled events to raise a hard exception, uncomment this line
  # unhandled_events_raise_exceptions!

  # To enable authentication, uncomment this line and set your API key.
  # It is recommended you pull your API keys from environment settings,
  # or use some other means to avoid committing the API keys in your source code.
  authenticate_with_mandrill_keys! Rails.application.credentials.mandrill[:webhook_secret_key]

  def handle_inbound(event_payload)
    head(:ok)
    msg = event_payload.msg

    from = msg['from_email']
    if Person.find_by(email_address: from) || User.find_by(email_address: from)
      text = msg['text']
      subject = msg['subject']
      ::AdminMailer.inbound_email(from: from, subject: subject, text: text).deliver_later
    end
  end
end
