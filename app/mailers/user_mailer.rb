# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def new_person_notify(email_address:, person:)
    @person = person
    mail(to: email_address,
         subject: "New Person: #{person.full_name}")
  end

  def session_reminder(user_id:, session_ids:)
    @user = User.find(user_id)
    @sessions = ResearchSession.find(session_ids)
    mail(to: @user.email_address,
         subject: 'Research Sessions Reminder!')
  end

  def reward_report(user_id:)
    @user = User.find(user_id)
    attachments["Rewards-#{Time.zone.today}.csv"] = { mime_type: 'application/csv',
                                                      content: Reward.export_csv }
    mail(to: @user.email_address, subject: 'Patterns Reward Report')
  end
end
