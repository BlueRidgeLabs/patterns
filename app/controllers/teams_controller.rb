# frozen_string_literal: true

class TeamsController < ApplicationController
  before_action :set_team, only: %i[show edit update destroy add remove]
  before_action :admin_needed
  # GET /teams
  # GET /teams.json
  def index
    # would love to sort this by active users.
    @teams = Team.all
  end

  # GET /teams/1
  # GET /teams/1.json
  def show
    @sessions = @team.research_sessions.includes(:invitations, :people).order(created_at: :desc).page(params[:sessions_page]).limit(5)
    @people = @sessions.map(&:people).flatten.uniq
    @changes = PaperTrail::Version.all.where(whodunnit: @team.users.map(&:id))
                                  .order(created_at: :desc)
                                  .page(params[:changes_page])
                                  .limit(10)
  end

  # GET /teams/new
  def new
    @team = Team.new
  end

  # GET /teams/1/edit
  def edit; end

  # POST /teams
  # POST /teams.json
  def create
    @team = Team.new(team_params)

    respond_to do |format|
      if @team.save
        format.html { redirect_to @team, notice: 'Team was successfully created.' }
        format.json { render :show, status: :created, location: @team }
      else
        format.html { render :new }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST
  def add; end

  # DELETE
  def remove; end

  # PATCH/PUT /teams/1
  # PATCH/PUT /teams/1.json
  def update
    respond_to do |format|
      if @team.update(team_params)
        format.html { redirect_to @team, notice: 'Team was successfully updated.' }
      else
        flash[:error] = @team.errors
        format.html { render :edit }
      end
      format.json { respond_with_bip(@team) }
      format.js
    end
  end

  # DELETE /teams/1
  # DELETE /teams/1.json
  def destroy
    @team.destroy
    respond_to do |format|
      format.html { redirect_to teams_url, notice: 'Team was successfully destroyed.' }
      format.json { head :no_content }
      format.js { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_team
    @team = Team.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def team_params
    params.require(:team).permit(:name, :finance_code, :description)
  end
end
