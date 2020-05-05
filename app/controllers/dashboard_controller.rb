# frozen_string_literal: true

class DashboardController < ApplicationController
  # New people that aren't 'verified',
  # Total # of verified dig members
  # Recent participants
  # Recent sessions
  # Upcoming Sessions
  # Newest tags
  # Most popular tags with numbers
  # Recent activity stream-> sessions, people edits, pool edits

  def index
    @new_people = Person.active.includes(:taggings).order('created_at DESC').where('signup_at > :startdate', startdate: 1.month.ago)

    @verified_count = Person.active.verified.size
    @unverified_count = Person.active.not_verified.size
    @deactivated_count = Person.deactivated.where('deactivated_at > ?', 1.month.ago).size
    @deactivated_people = Person.deactivated.where(active: false).order('deactivated_at DESC').limit(10)

    @last_logins = User.approved.order('last_sign_in_at DESC').all
    @one_month_reward = Reward.where('created_at > ?', 1.month.ago).sum(&:amount)
    @six_month_reward = Reward.where('created_at > ?', 6.months.ago).sum(&:amount)
    @twelve_month_reward = Reward.where('created_at > ?', 1.year.ago).sum(&:amount)

    @one_month_people = Person.active.where(id: Reward.select('distinct person_id').where('created_at > ?', 1.month.ago).pluck(:person_id).uniq).size
    @six_month_people = Person.active.where(id: Reward.select('distinct person_id').where('created_at > ?', 6.months.ago).pluck(:person_id).uniq).size
    @twelve_month_people = Person.active.where(id: Reward.select('distinct person_id').where('created_at > ?', 1.year.ago).pluck(:person_id).uniq).size

    @popular_tags   = Person.includes(:taggings).active.tag_counts.order('taggings_count DESC').limit(10)
    @new_tags       = Person.includes(:taggings).active.tag_counts.order('id desc').limit(10)

    @recent_participants = ResearchSession.includes(:invitations,:people).order('research_sessions.created_at DESC').where('start_datetime < ?', Time.current).limit(10).map(&:people).flatten.uniq.take(10)
    @recent_sessions = ResearchSession.includes(:invitations).order('created_at DESC').limit(10)

    @upcoming_participants = ResearchSession.includes(:invitations).where('research_sessions.start_datetime between NOW() and ?', 1.week.from_now).map(&:people).flatten.uniq
    @upcoming_sessions = ResearchSession.includes(:invitations).where('start_datetime between NOW() and ?', 1.week.from_now)
    @cart_people = CartsPerson.includes(:cart, :person).all.limit(20)
  end
end
