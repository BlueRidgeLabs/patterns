# frozen_string_literal: true

json.extract! @twilio_message, :message_sid, :created_at, :updated_at
