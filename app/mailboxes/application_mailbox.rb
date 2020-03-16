# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  # this is security through obscurity
  routing /^signed\.consent\.#{ENV['MANDRILL_INGRESS_API_KEY']}@/i => :consent_form
end
