# frozen_string_literal: true

class DigitalGiftsController < ApplicationController
  before_action :set_digital_gift, only: %i[show edit update destroy]
  skip_before_action :authenticate_user!, only: :api_gift

  # GET /digital_gifts
  # GET /digital_gifts.json
  def index
    if current_user.admin?
      @digital_gifts = DigitalGift.order(id: 'desc').includes(:reward).page(params[:page])
    else
      team_ids = current_user.team.users.map(&:id)
      @digital_gifts = DigitalGift.where(user_id:team_ids).order(id: 'desc').includes(:reward).page(params[:page])
    end
  end

  # GET /digital_gifts/1
  # GET /digital_gifts/1.json
  def show; end

  # GET /digital_gifts/new
  def new
    @digital_gift = DigitalGift.new
  end

  def create
    # this is kinda horrific
    klass = GIFTABLE_TYPES.fetch(dg_params[:giftable_type])
    @giftable = klass.find(dg_params[:giftable_id])
    @success = true
    if @giftable.nil?
      flash[:error] = 'No giftable object present'
      @success = false
    end

    if params[:giftable_type] == 'Invitation' && !@giftable&.attended?
      flash[:error] = "#{@giftable.person.full_name} isn't marked as 'attended'."
      @success = false
    end

    if params[:giftable_type] == 'Invitation' && @giftable.rewards.find {|r| r.rewardable_type == 'DigitalGift'}.present?
      flash[:error] = "#{@giftable.person.full_name} Already has a digital gift"
      @success = false
    end

    # cover fees
    if params[:amount].to_money + 2.to_money >= current_user.available_budget
      flash[:error] = 'Insufficient Team Budget'
      @success = false # placeholder for now
    end

    # so, the APIs are wonky
    # if params[:amount].to_money >= DigitalGift.current_budget
    #   flash[:error] = 'Insufficient Gift Rocket Budget'
    #   @success = false # placeholder for now
    # end
    if @success
      @dg = DigitalGift.new(user_id: current_user.id,
                          created_by: current_user.id,
                          amount: dg_params['amount'],
                          person_id: dg_params['person_id'],
                          giftable_type: dg_params['giftable_type'],
                          giftable_id: dg_params['giftable_id'])

      @reward = Reward.new(user_id: current_user.id,
                         created_by: current_user.id,
                         person_id: dg_params['person_id'],
                         amount: dg_params['amount'],
                         reason: dg_params['reason'],
                         notes: dg_params['notes'],
                         giftable_type: dg_params['giftable_type'],
                         giftable_id: dg_params['giftable_id'],
                         finance_code: current_user&.team&.finance_code,
                         team: current_user&.team,
                         rewardable_type: 'DigitalGift')
      if @dg.valid? # if it's not valid, error out
        @dg.request_link # do the thing!
        if @dg.save
          @reward.rewardable_id = @dg.id
          @success = @reward.save
          @dg.reward_id = @reward.id # is this necessary?
          @dg.save
        end
      else
        flash[:error] = @dg.errors
        @success = false
      end
    end

    respond_to do |format|
      format.js {}
    end
  end

  def api_create
    # apithis is horrific too
    # https://blog.arkency.com/2014/07/4-ways-to-early-return-from-a-rails-controller/
    validate_api_args
    return if performed?
    
    if @research_session.can_survey? && !@research_session.is_invited?(@person)
      @invitation = Invitation.new(aasm_state: 'attended',
                           person_id: @person.id,
                           research_session_id: @research_session.id)
      @invitation.save

      @digital_gift = DigitalGift.new(user_id: @user.id,
                                      created_by: @user.id,
                                      amount: api_params['amount'],
                                      person_id: @person.id,
                                      giftable_type: 'Invitation',
                                      giftable_id: @invitation.id)

      @reward = Reward.new(user_id: @user.id,
                           created_by: @user.id,
                           person_id: @person.id,
                           amount: api_params['amount'],
                           reason: 'survey',
                           giftable_type: 'Invitation',
                           giftable_id: @invitation.id,
                           finance_code: @user&.team&.finance_code,
                           team: @user&.team,
                           rewardable_type: 'DigitalGift')
      if @digital_gift.valid?
        @digital_gift.request_link # do the thing!
        if @digital_gift.save
          @reward.rewardable_id = @digital_gift.id
          @success = @reward.save
          @digital_gift.reward_id = @reward.id # is this necessary?
          @digital_gift.save
          render status: :created, json: { success: true, link: @digital_gift.link, msg:'Successfully created a gift card for you!' }.to_json
        end
      else
        Airbrake.notify("Can't create Digital Gift #{@digital_gift.attributes}, #{@digital_gift.errors.full_messages.join("\n")}")
        render status: :unprocessable_entity, json: { success: false, msg: @digital_gift.errors.full_messages}.to_json
      end
    else
      render status: :unprocessable_entity, json: { success: false, msg: @digital_gift.errors.full_messages}.to_json
    end
  end

  def validate_api_args
    @user = User.find_by(token: api_params['api_token'])
    render status: :unauthorized  and return if @user.blank? || !@user.admin?

    @research_session = ResearchSession.find(api_params['research_session_id'])
    @person = Person.active.find api_params['person_id']
    render status: :not_found and return if @person.blank? || @research_session.blank?
  end
  # GET /digital_gifts/1/edit
  # def edit; end

  # we don't create, destroy or update these via controller

  # # POST /digital_gifts
  # # POST /digital_gifts.json
  # def create
  #   @digital_gift = DigitalGift.new(digital_gift_params)

  #   respond_to do |format|
  #     if @digital_gift.save
  #       format.html { redirect_to @digital_gift, notice: 'DigitalGift was @successfully created.' }
  #       format.json { render :show, status: :created, location: @digital_gift }
  #     else
  #       format.html { render :new }
  #       format.json { render json: @digital_gift.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # # PATCH/PUT /digital_gifts/1
  # # PATCH/PUT /digital_gifts/1.json
  # def update
  #   respond_to do |format|
  #     if @digital_gift.update(digital_gift_params)
  #       format.html { redirect_to @digital_gift, notice: 'DigitalGift was @successfully updated.' }
  #       format.json { render :show, status: :ok, location: @digital_gift }
  #     else
  #       format.html { render :edit }
  #       format.json { render json: @digital_gift.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # DELETE /digital_gifts/1
  # DELETE /digital_gifts/1.json
  # def destroy
  #   @digital_gift.destroy
  #   respond_to do |format|
  #     format.html { redirect_to digital_gifts_url, notice: 'DigitalGift was @successfully destroyed.' }
  #     format.json { head :no_content }
  #   end
  # end

  private

    def api_params
      params.permit(:person_id,
                    :api_token,
                    :research_session_id,
                    :amount)
    end

    def dg_params
      params.permit(:person_id,
        :user_id,
        :notes,
        :reason,
        :amount,
        :giftable_type,
        :giftable_id)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_digital_gift
      @digital_gift = DigitalGift.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def digital_gift_params
      params.fetch(:digital_gift, {})
    end
end
