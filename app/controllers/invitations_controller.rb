# frozen_string_literal: true

# == Schema Information
#
# Table name: invitations
#
#  id                  :integer          not null, primary key
#  time_slot_id        :integer
#  person_id           :integer
#  created_at          :datetime
#  updated_at          :datetime
#  user_id             :integer
#  event_id            :integer
#  event_invitation_id :integer
#

# FIXME: Refactor and re-enable cop
# rubocop:disable Metrics/ClassLength
class InvitationsController < ApplicationController
  # this is accessed by people, without usernames/passwords.
  # confitmation, updates, etc.
  skip_before_action :authenticate_user!, only: %i[show confirm cancel]
  before_action :set_visitor, only: %i[show confirm cancel]
  before_action :set_invitation
  # need a before action here for authentication of invitation changes

  def new
    @user = current_user
    @research_session = ResearchSession.find(params[:research_session_id])
    @invitation = Invitation.new
  end

  # rubocop:disable Metrics/MethodLength
  # TODO: refactor
  def create
    # params should include a research_session_id
    @invitation = Invitation.new(invitation_params)
    if @invitation.save
      @invitation.invite!
      flash[:notice] = "A session has been booked for #{@invitation.start_datetime_human}"

    else
      flash[:error] = "No time slot was selected, couldn't create the invitation"
    end

    @person = @invitation.person
    respond_to do |format|
      format.js { }
      format.html { render :new }
    end
  end
  # rubocop:enable Metrics/MethodLength

  # no authorization here. yet.

  def index
    @invitations = Invitation.order(id: :desc).page(params[:page])
  end

  def show
    redirect_to url_for(@invitation.research_session)
  end

  def edit; end

  def event
    events = @invitation.aasm.events(permitted: true).map(&:name).map(&:to_s)
    event = events.detect { |a| a == params[:event] }

    if event.nil?
      render status: :bad_request
      return
    end

    # want explicit 'and' here.
    if @invitation.send("may_#{event}?")
      @invitation.send("#{event}!") && @invitation.save
      flash[:notice] = I18n.t(
        "invitation.event_success",
        event: event.capitalize,
        person_name: @invitation.person.full_name
      )
    elsif @invitation.errors.empty?
      flash[:alert] = "Error, cannot update invitation"
    else
      @invitation.errors.messages[:base].each { |e| flash[:alert] = e }
    end

    respond_to do |format|
      # /sessions/:research_session_id/invitations_panel
      format.js
      format.json do
        { invitation_id: @invitation.id, state: @invitation.aasm_state }
      end
    end
  end

  # these are our methods for people and users to edit invitations
  def confirm
    # can't confirm invitation in the past!
    render false && return unless @invitation.start_datetime > Time.current
    if @invitation.confirm! && @invitation.save
      flash[:notice] = "You are confirmed for #{@invitation.start_datetime_human}, with #{@invitation.user.name}."
    else
      flash[:alert] = "Error"
    end
    respond_to do |format|
      format.html { }
      format.json do
        { invitation_id: @invitation.id, state: @invitation.aasm_state }
      end
    end
  end

  def cancel
    if @invitation.cancel!
      flash[:notice] = "Your session with #{@invitation.user.name} has been cancelled"
      @invitation.save
    else
      flash[:alert] = "Error"
    end
    respond_to do |format|
      # where to redirect for person?
      format.html { }
      format.json do
        { invitation_id: @invitation.id, state: @invitation.aasm_state }
      end
    end
  end

  def update
    # flash a  notice here and return a js file that reloads the page
    # or calls turbolinks to reload or somesuch
    if @invitation.update(update_params)
      flash[:notice] = "invitation updated"
    else
      flash[:error]  = "update failed"
    end

    respond_to do |format|
      format.html { redirect_to(:back) }
    end
  end

  def destroy
    @invitation.destroy!
    respond_to do |format|
      format.html { redirect_to invitation_url }
      format.json { head :no_content }
    end
  end

  private
    def set_invitation
      @set_invitation ||= Invitation.find_by(id: params[:id])
      @invitation = @set_invitation
    end

    def set_visitor
      @person = Person.find_by(token: params[:token]) if params[:token].present?
      # if we don't have a person, see if we have a user's token.
      # thus we can provide a feed without auth1
      visitor # sets our visitor object
      @invitation ||= Invitation.find_by(id: params[:id])

      return false unless @invitation&.owner_or_invitee?(@visitor)

      @visitor.nil? ? false : true
    end

    def visitor
      @visitor ||= @person || current_user
      PaperTrail.request.whodunnit = @visitor
      @visitor
    end

    def event_params
      params.permit(:event_id)
    end

    def invitation_params
      params.require(:invitation).permit(
        :person_id,
        :research_session_id,
        :user_id,
        :aasm_event,
        :aasm_state
      )
    end

    def update_params
      params.permit(
        :id,
        :person_id,
        :research_session_id,
        :user_id,
        :aasm_event,
        :aasm_state
      )
    end

    def person_params
      params.permit(:email_address, :person_id, :token)
    end
end
# rubocop:enable Metrics/ClassLength
