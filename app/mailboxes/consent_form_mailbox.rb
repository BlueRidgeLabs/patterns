# frozen_string_literal: true

class ConsentFormMailbox < ApplicationMailbox
  def process
    token = mail.subject
    return if token.nil?

    @person = Person.find_by(token: token)

    return if @person.nil?
    return if @person.consent_form.attached?
    return unless mail.attachments.present?

    @person.consent_form.attach(attachments.first)
  end

  def attachments
    @_attachments ||= mail.attachments.map do |attachment|
      blob = ActiveStorage::Blob.create_after_upload!(
        io: StringIO.new(attachment.body.to_s),
        filename: attachment.filename,
        content_type: attachment.content_type
      )
      blob
    end
  end
end
