# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]
  before_action :admin?
  # GET /users
  def index
    User.per_page = 100
    @users = User.includes(:rewards, :team).order("approved desc").paginate(page: params[:page])
  end

  # GET /users/1
  def show
    @changes = PaperTrail::Version.where(whodunnit: @user.id)
                                  .order(created_at: :desc)
                                  .page(params[:changes_page])
    around_now = Time.zone.now - 7.days..Time.zone.now + 7.days
    @sessions = ResearchSession.includes(:user)
                               .where(start_datetime: around_now, user_id: @user.id)
                               .page(params[:sessions_page])
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit; end

  def changes
    @changes = PaperTrail::Version.order("id desc").page(params[:page])
  end

  def finance
    @start_date = params[:start_date].presence || Time.current.beginning_of_year
    @end_date = params[:end_date].presence || Time.current
    codes = Reward.distinct.pluck(:finance_code).compact
    @results = codes.map do |code|
      amt = Money.new(Reward.where(created_at: @start_date..@end_date, finance_code: code).sum(:amount_cents), "USD")
      count = Reward.where(created_at: @start_date..@end_date, finance_code: code).size
      { code: code, amount: amt, count: count }
    end
  end

  # POST /users
  def create
    @user = User.new(user_create_params)

    if @user.save
      redirect_to @user, notice: I18n.t("user.successfully_created")
    else
      render :new
    end
  end

  # PATCH/PUT /users/1
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to(@user, notice: I18n.t("user.successfully_updated")) }
      else
        format.html { render :edit }
      end
      format.json { respond_with_bip(@user) }
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy
    redirect_to users_url, notice: "User was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def user_params
      params.require(:user).permit(:name,
                                   :approved,
                                   :phone_number,
                                   :email_address,
                                   :team_id)
    end

    def admin?
      redirect_to root_url unless current_user.admin?
    end

    def user_create_params
      params.require(:user).permit(:name,
                                   :approved,
                                   :phone_number,
                                   :email_address,
                                   :team_id,
                                   :password,
                                   :password_confirmation)
    end
end
