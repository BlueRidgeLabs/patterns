# frozen_string_literal: true

# FIXME: Refactor and re-enable cop
# this is primarily used by admins to track upcoming sessions...
class CalendarController < ApplicationController
  # this is so that people can also visit the calendar.
  # identified by their secure token.
  skip_before_action :authenticate_user!, if: :person?
  skip_after_action :update_user_activity, only: %i[feed admin_feed]

  include ActionController::MimeResponds

  def feed # TODO: refactor into calendarable.
    calendar = Icalendar::Calendar.new
    case visitor.class.to_s
    when 'Person'
      visitor.invitations.each { |i| calendar.add_event(i.to_ics) }
    when 'User'
      visitor.research_sessions.each { |r| calendar.add_event(r.to_ics) }
    end
    calendar.publish
    render plain: calendar.to_ical
  end

  def admin_feed
    calendar = Icalendar::Calendar.new
    if visitor&.admin?
      ResearchSession.includes(:invitations, user: :team).
        in_range(6.months.ago..3.months.from_now).
        find_each { |e| calendar.add_event(e.to_ics) }
    end
    calendar.publish
    render plain: calendar.to_ical
  end

  private

    # this does the token based auth for users and persons
    def person?
      @person = nil
      if allowed_params[:token].present?
        @person = Person.find_by(token: allowed_params[:token])
        # if we don't have a person, see if we have a user's token.
        # thus we can provide a feed without auth1
        @person = User.find_by(token: allowed_params[:token]) if @person.nil?
      elsif allowed_params[:id].present?
        @person = Person.find_by(id: allowed_params[:id])
      end
      @person.nil? ? false : true
    end

    # both types can visit the page. they have the same interface
    # TODO fix this
    def visitor # this looks like it needs work
      @visitor ||= @person || current_user
      # PaperTrail.request.whodunnit = @visitor
      # @visitor
    end

    def allowed_params
      params.permit(:token,
        :id,
        :research_session_id,
        :user_id,
        :start,
        :end,
        :type,
        :invitation_id,
        :default_time)
    end

    def default_time
      return invitation.start_datetime.strftime('%F') if invitation
      return research_session.start_datetime.strftime('%F') if research_session
      return Time.zone.parse(allowed_params['default_time']).strftime('%F') if allowed_params['default_time']

      Time.current.strftime('%F')
    end

    def cal_params
      # default the start of our calendar to today.
      end_time = (Time.zone.today + 7.days).strftime('%m/%d/%Y')
      start_time = Time.zone.today.strftime('%m/%d/%Y')

      defaults = { start: start_time, end: end_time }
      params.permit(:token, :start, :end).reverse_merge(defaults)

      # full calendar uses dashes, not slashes. argh.
      params.transform_values do |v|
        /\d{4}-\d{2}-\d{2}/.match?(v) ? Time.zone.parse(v).strftime('%m/%d/%Y') : v
      end
    end
end
