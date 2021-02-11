# frozen_string_literal: true

# see here: https://dev.to/matiascarpintini/magic-links-with-ruby-on-rails-and-devise-4e3o
class EmailLink < ApplicationRecord
  belongs_to :user
  after_commit :send_mail

  scope :active, -> { where('expires_at > ?', Time.zone.now).where(utilized: false) }

  def self.generate(email)
    user = User.approved.find_by(email: email)
    return nil unless user

    create(user: user, expires_at: Time.zone.today + 1.day, token: generate_token)
  end

  def self.generate_token
    Devise.friendly_token.first(16)
  end

  def utilized!
    self.utilized = true
    save!
  end

  private

  def send_mail
    # not backgrounding, because we want it fast
    EmailLinkMailer.sign_in_mail(self).deliver_now
  end
end
