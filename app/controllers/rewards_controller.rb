# frozen_string_literal: true

class RewardsController < ApplicationController
  before_action :set_reward, only: %i[show edit update destroy]
  helper_method :sort_column, :sort_direction

  # GET /rewards
  # GET /rewards.csv
  def index
    @q_rewards = if current_user.admin?
      Reward.includes(:user, :rewardable).ransack(params[:q])
    else
      Reward.includes(:user, :rewardable).where(created_by: current_user.id).ransack(params[:q])
    end
    if @q_rewards.sorts.empty?
      @q_rewards.sorts = [sort_column + " " + sort_direction]
    end
    respond_to do |format|
      format.html do
        @rewards = @q_rewards.result.includes(:person, :rewardable, :giftable).order(id: :desc).page(params[:page])
        # @recent_signups = Person.no_signup_card.paginate(page: params[:page]).where('signup_at > :startdate', { startdate: 3.months.ago }).order('signup_at DESC')
      end
      format.csv do
        @rewards = @q_rewards.result.includes(:person, :rewardable, :giftable)
        send_data @rewards.export_csv, filename: "Rewards-#{Time.zone.today}.csv"
      end
    end
  end

  # GET /recent_signups
  # GET /recent_signups.csv
  # def recent_signups
  #   @q_recent_signups = Person.no_signup_card.ransack(params[:q_signups], search_key: :q_signups)

  #   @q_recent_signups.created_at_date_gteq = 3.weeks.ago.strftime('%Y-%m-%d') unless params[:q_signups]

  #   @recent_signups = @q_recent_signups.result.order(id: :desc).page(params[:page_signups])

  #   @new_rewards = []
  #   @recent_signups.length.times do
  #     @new_grewards << Reward.new
  #   end
  # end

  # GET /rewards/1
  # GET /rewards/1.json
  def show; end

  # GET /rewards/new
  def new
    @gift_reward = Reward.new
  end

  # GET /rewards/1/edit
  def edit; end

  # POST /rewards
  # POST /rewards.json
  # TODO
  # FIXME
  # def create
  #   # this is gonna be a doozy
  #   # we don't create rewards directly. First we find the rewardable obj, then
  #   # we associate it with the created reward.
  #   # this endpoint is likely unecessary
  #   @reward = Reward.new(reward_params)

  #   @total = @reward.person.blank? ? @reward.amount : @reward.person.rewards_total

  #   @reward.created_by = current_user.id
  #   @reward.finance_code = current_user&.team&.finance_code
  #   @reward.team = current_user&.team
  #   @reward.save

  #   @create_result = @reward.save
  #   respond_to do |format|
  #     if @create_result
  #       format.js {}
  #       format.json {}
  #       format.html { redirect_to @reward, notice: 'Reward was successfully created.'  }
  #     else
  #       flash[:error] = "Error adding Reward! #{@reward.errors.full_messages.join(', ')}"
  #       format.js {}
  #       format.html { render action: 'edit' }
  #       format.json { render json: @reward.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # takes an card_activation_id, person_id, and sessionid
  # FIXME
  # TODO
  def assign
    ## todo, gotta find the right class and object

    klass = reward_params["rewardable_type"].classify.constantize
    @rewardable = klass.find(reward_params["rewardable_id"])
    @success = false
    # TODO: Refactor
    if @rewardable && Reward.find_by(rewardable_type: @rewardable.class.to_s,
                                     rewardable_id: @rewardable.id).nil?
      @reward = Reward.new(rewardable_type: @rewardable.class,
                           rewardable_id: @rewardable.id,
                           amount: @rewardable.amount,
                           reason: reward_params["reason"],
                           user_id: current_user.id,
                           person_id: reward_params["person_id"],
                           giftable_type: reward_params["giftable_type"],
                           giftable_id: reward_params["giftable_id"],
                           finance_code: current_user&.team&.finance_code,
                           team: current_user&.team,
                           created_by: current_user.id)
      @success = @reward.save
      @rewardable.reward_id = @reward.id
      @rewardable.save
    else
      flash[:error] = "Reward doesn't exist"
    end
    @person = Person.find reward_params["person_id"]
    @total = @person.rewards_total

    respond_to do |format|
      if @success
        format.js { render action: :create }
        format.json { }
        format.html { redirect_to @reward, notice: "Reward was successfully created." }
      else
        format.js { }
        format.html { render action: "edit" }
        format.json { render json: @reward.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rewards/1
  # PATCH/PUT /rewards/1.json
  def update
    respond_to do |format|
      if @reward.update(reward_params)
        format.html { redirect_to @reward, notice: "Reward was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @reward.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rewards/1
  # DELETE /rewards/1.json
  def destroy
    @giftable = @reward.giftable
    @reward.destroy
    @giftable&.reload # weirdo.
    respond_to do |format|
      format.html { redirect_back(fallback_location: rewards_path) }
      format.json { head :no_content }
      format.js { }
    end
  end

  def modal
    klass = GIFTABLE_TYPES.fetch(params[:giftable_type])
    @giftable = klass.find(params[:giftable_id])
    @gift_cards = if current_user.admin?
      GiftCard.unassigned.active
    else
      GiftCard.unassigned.active.where(user_id: current_user.id)
    end
    @reward = Reward.new
    @cash_card = CashCard.new
    @digital_gift = DigitalGift.new
    @last_reward = Reward.last # default scope is id: :desc
    respond_to do |format|
      format.html
      format.js
    end
  end

  def sort_column
    Reward.column_names.include?(params[:sort]) ? params[:sort] : "people.id"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_reward
      @reward = Reward.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def reward_params
      params.require(:reward).permit(
        :person_id,
        :notes,
        :user_id,
        :created_by,
        :reason,
        :amount,
        :rewardable_id,
        :rewardable_type,
        :giftable_id,
        :giftable_type,
        :team_id,
        :finance_code
      )
    end
end
