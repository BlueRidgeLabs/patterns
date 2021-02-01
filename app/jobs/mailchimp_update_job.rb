# frozen_string_literal: true

class MailchimpUpdateJob # this is broken
  include Sidekiq::Worker
  sidekiq_options retry: 1

  def perform(id, status)
    Rails.logger.info '[MailchimpSave] job enqueued'
    person = Person.unscoped.find id
    if person.email_address.present?
      begin
        gibbon = Gibbon::Request.new
        gibbon.lists(Rails.application.credentials.mailchimp[:list_id]).members(person.md5_email).upsert(body: { # rubocop:todo Rails/SkipsModelValidations
                                                                                                           email_address: person.email_address.downcase,
                                                                                                           status: status,
                                                                                                           merge_fields: { FNAME: person.first_name || '',
                                                                                                                           LNAME: person.last_name || '',
                                                                                                                           MMERGE3: person.geography_id || '',
                                                                                                                           MMERGE4: person.postal_code || '',
                                                                                                                           MMERGE5: person.participation_type || '',
                                                                                                                           MMERGE6: person.voted || '',
                                                                                                                           MMERGE7: person.called_311 || '',
                                                                                                                           MMERGE8: person.primary_device_description || '',
                                                                                                                           MMERGE9: person.secondary_device_id || '',
                                                                                                                           MMERGE10: person.secondary_device_description || '',
                                                                                                                           MMERGE11: person.primary_connection_id || '',
                                                                                                                           MMERGE12: person.primary_connection_description || '',
                                                                                                                           MMERGE13: person.primary_device_id || '',
                                                                                                                           MMERGE14: person.preferred_contact_method || '' }
                                                                                                         })

        Rails.logger.info("[People->sendToMailChimp] Sent #{person.id} to Mailchimp")
      rescue Gibbon::MailChimpError => e
        Rails.logger.fatal("[People->sendToMailChimp] fatal error sending #{person.id} to Mailchimp: #{e.message}")
      end
    end
  end
end
