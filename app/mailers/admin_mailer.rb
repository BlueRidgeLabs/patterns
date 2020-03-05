# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  def deactivate(person:)
    admin_email = ENV["MAIL_ADMIN"]
    @person = person
    mail(to: admin_email,
         from: admin_email,
         subject: "Deactivated: #{person.full_name}")
  end

  def inbound_email(from:, subject:, text:)
    mail(to: ENV["MAIL_ADMIN"],
         reply_to: from,
         subject: "from: #{from}, subj:#{subject}",
         body: text)
  end

  def participation_level_change(results, to)
    if results.present?
      msg = %(Hi!\n Participation level changes:\n)
      results.each do |r|
        next if r[:id].nil?

        person = Person.find r[:id]
        msg += %(*   #{person.full_name} changed from #{r[:old]} to #{r[:new]}. link: https://#{HOSTNAME}/people/#{person.id} \n)
      end
      msg += "\nthanks"
      mail(to: to, from: ENV["MAIL_ADMIN"], subject: "Participation level changes", body: msg)
    end
  end
end
