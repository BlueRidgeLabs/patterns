# frozen_string_literal: true

module InvitationHelper
  def invitation_action_name(name)
    Rails.logger.info('foobar')
    r = { invite: 'invited?',
          remind:'reminded?',
          confirm: 'confirmed?',
          attend: 'attended?',
          cancel: 'canceled?',
          miss: 'missed?' }
    r[name]
  end
end
