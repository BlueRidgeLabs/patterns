# frozen_string_literal: true

# == Schema Information
#
# Table name: mailchimp_updates
#
#  id          :integer          not null, primary key
#  raw_content :text(65535)
#  email       :string(255)
#  update_type :string(255)
#  reason      :string(255)
#  fired_at    :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class MailchimpUpdate < ApplicationRecord # largely unused
  scope :latest, -> { order('fired_at DESC') }
  after_save :update_person
  self.per_page = 15
  def update_person
    Rails.logger.info("[ MailchimpUpdate#updatePerson ] email = #{email} update_type = #{update_type}")

    Person.where(email_address: email).find_each do |person|
      if update_type == 'unsubscribe'
        person.tag_list.add(update_type)
        person.deactivate!('mailchimp_api')
      end

      content = "MailChimp Webhook Update: #{update_type} because reason = #{reason} at #{fired_at}"
      Comment.create(content: content,
                     commentable_type: 'Person',
                     commentable_id: person.id)
    end
  end
end
