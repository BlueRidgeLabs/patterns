# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  # this is security through obscurity
  routing /^signed\.consent/ => :consent_form
end
