# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  # this is security through obscurity
  routing /consent/ => :consent_form
end
