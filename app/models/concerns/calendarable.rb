# frozen_string_literal: true

require 'active_support/concern'

# to be "calendarable", must have or delegate to
# start_datetime
# end_datetime
# description
# title
# a user or person

module Calendarable
  extend ActiveSupport::Concern
  # http://stackoverflow.com/questions/7323793/shared-scopes-via-module
  # http://stackoverflow.com/questions/2682638/finding-records-that-overlap-a-range-in-rails
  included do
    # doesn't work if you delegate start_datetime etc.
    # how do we fix?
    scope :in_range, lambda { |range|
      where("(#{table_name}.start_datetime BETWEEN ? AND ? OR #{table_name}.end_datetime BETWEEN ? AND ?) OR (#{table_name}.start_datetime <= ? AND #{table_name}.end_datetime >= ?)", range.first, range.last, range.first, range.last, range.first, range.last)
    }

    scope :for_today, lambda {
      where("#{table_name}.start_datetime >= ? and #{table_name}.end_datetime <= ?",
            Time.zone.now.beginning_of_day,
            Time.zone.now.end_of_day)
    }

    scope :for_today_and_tomorrow, lambda {
      where("#{table_name}.start_datetime >= ? and #{table_name}.end_datetime <= ?",
            Time.zone.now.beginning_of_day,
            Time.zone.now.end_of_day + 1.day)
    }
  end

  def not_overlap?(other)
    !overlap?(other)
  end

  def overlap?(other)
    ((start_datetime - other.end_datetime) * (other.start_datetime - end_datetime) >= 0)
  end

  def to_ics
    e               = Icalendar::Event.new
    e.summary       = title + " (#{user.name})"
    e.dtstart       = Icalendar::Values::DateTime.new(start_datetime)
    e.dtend         = Icalendar::Values::DateTime.new(end_datetime)
    e.description   = cal_description
    e.url           = generate_url
    e.uid           = generate_ical_id
    add_alarm(e)
  end

  def date
    start_datetime.to_date
  end

  def to_time_and_weekday
    "#{start_datetime.strftime('%l:%M %p').lstrip} - #{end_datetime.strftime('%l:%M %p').lstrip} #{start_datetime.strftime('%a %d')}"
  end

  def to_weekday_and_time
    "#{start_datetime.strftime('%a %d')} #{start_datetime.strftime('%l:%M %p').lstrip} - #{end_datetime.strftime('%l:%M %p').lstrip}"
  end

  def start_datetime_human
    "#{start_datetime.strftime('%l:%M%p, %a %b').lstrip} #{start_datetime.strftime('%d').to_i.ordinalize}"
  end

  def duration_human
    "#{start_datetime.strftime('%l:%M%p').lstrip}-#{end_datetime.strftime('%l:%M%p, %a %b').lstrip} #{start_datetime.strftime('%d').to_i.ordinalize}"
  end

  def bot_duration
    "from #{start_datetime.strftime('%l:%M%p').lstrip} to #{end_datetime.strftime('%l:%M%p').lstrip}"
  end

  private

  def cal_description
    if defined? person # it's an invitation
      res = description + %(
          tel: #{person.phone_number}\n
          email: #{person.email_address}\n
        )
      res
    elsif defined?(people) # it's a reservation
      %(Created by: #{user.name}
Team: #{user.team.name}
People: #{invitations.size}
Description:#{description}
tags: #{cached_tag_list})
    else
      description
    end
  end

  def generate_url
    if self.class.to_s == 'Invitation'
      "https://#{ENV['PRODUCTION_SERVER']}/sessions/#{research_session.id}"
    elsif self.class.to_s == 'ResearchSession'
      "https://#{ENV['PRODUCTION_SERVER']}/sessions/#{id}"
    end
  end

  def add_alarm(event)
    # only add alarms for the actual reservation
    case self.class.name.demodulize
    when 'ResearchSession'
      generate_alarm(event)
    else
      event
    end
  end

  def generate_alarm(event)
    user_email = defined?(user) ? user.email : ENV['MAIL_ADMIN']
    event.alarm do |alarm|
      alarm.attendee = "mailto:#{user_email}"
      alarm.summary  = description
      alarm.trigger  = '-P1DT0H0M0S' # 1 day before
    end
    event
  end

  def date_plus_time(date, time)
    (Date.strptime(date, '%m/%d/%Y') + Time.zone.parse(time).seconds_since_midnight.seconds)
  end

  # must by reasonably unique
  def generate_ical_id
    Digest::SHA1.hexdigest(id.to_s + start_datetime.to_s)
  end
end
