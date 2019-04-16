# frozen_string_literal: true

class DigitalGiftsController < ApplicationController
  before_action :set_digital_gift, only: %i[show sent]
  skip_before_action :authenticate_user!, only: %i[api_create webhook]
  skip_before_action :verify_authenticity_token, only: :webhook
  # GET /digital_gifts
  # GET /digital_gifts.json
  def index
    if current_user.admin?
      @digital_gifts = DigitalGift.order(id: 'desc').includes(:reward).page(params[:page])
    else
      team_ids = current_user.team.users.map(&:id)
      @digital_gifts = DigitalGift.where(user_id: team_ids).order(id: 'desc').includes(:reward).page(params[:page])
    end
  end

  def webhook
    @digital_gift = DigitalGift.find_by(gift_id: params[:payload][:id])
    if @digtial_gift.nil? || !valid_request?(request)
      render json: { success: false }
    else
      if params[:event].match? 'gift'
        @digital_gift.giftrocket_status = params[:event].delete('gift.')
        @digital_gift.save
      end
      render json: { success: true }
    end
  end

  def sent
    @digital_gift.sent = true
    @digital_gift.sent_by = current_user.id
    @digital_gift.sent_at = Time.current
    @digital_gift.save
    respond_to do |format|
      format.js {}
    end
  end

  # GET /digital_gifts/1
  # GET /digital_gifts/1.json
  def show
    @comment = Comment.new commentable: @digital_gift
  end

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

    if params[:giftable_type] == 'Invitation' && @giftable.rewards.find { |r| r.rewardable_type == 'DigitalGift' }.present?
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

    # https://api.rubyonrails.org/v4.1.4/classes/ActionController/Metal.html#method-i-performed-3F
    return if performed?

    if @research_session.can_survey? && !@research_session.is_invited?(@person)
      @invitation = Invitation.new(aasm_state: 'attended', person_id: @person.id, research_session_id: @research_session.id)
      @invitation.save

      @digital_gift = DigitalGift.new(user_id: @user.id, created_by: @user.id, amount: api_params['amount'], person_id: @person.id, giftable_type: 'Invitation', giftable_id: @invitation.id)

      @reward = Reward.new(user_id: @user.id, created_by: @user.id, person_id: @person.id, amount: api_params['amount'], reason: 'survey', giftable_type: 'Invitation', giftable_id: @invitation.id, finance_code: @user&.team&.finance_code, team: @user&.team, rewardable_type: 'DigitalGift')
      if @digital_gift.valid?
        @digital_gift.request_link # do the thing!
        if @digital_gift.save
          @reward.rewardable_id = @digital_gift.id
          @success = @reward.save
          @digital_gift.reward_id = @reward.id # is this necessary?
          @digital_gift.sent = true
          @digital_gift.sent_at = Time.current
          @digital_gift.sent_by = @user.id
          @digital_gift.save
          render status: :created, json: { success: true, link: @digital_gift.link, msg: 'Successfully created a gift card for you!' }.to_json
        end
      else
        Airbrake.notify("Can't create Digital Gift, not valid #{api_params}")
        render status: :unprocessable_entity, json: { success: false, msg: 'digital gift invalid' }.to_json
      end
    else
      Airbrake.notify("Can't create Digital Gift, research_session busted: #{api_params}")
      render status: :unprocessable_entity, json: { success: false, msg: 'Something has gone wrong. we will be in touch soon! research_session invalid' }.to_json
    end
  end

  def validate_api_args
    @user = User.where(token: request.headers['AUTHORIZATION']).first if request.headers['AUTHORIZATION'].present?

    render(status: :unauthorized, json: { success: false }.to_json)  && return if @user.blank? || !@user.admin?

    @research_session = ResearchSession.where(api_params['research_session_id']).first
    phone = PhonyRails.normalize_number(CGI.unescape(api_params['phone_number']))
    @person = Person.active.where(phone_number: phone).first

    if @person.blank? || @research_session.blank? || @user.blank?
      Airbrake.notify("person: #{@person}, rs: #{@research_session}, params:#{api_params}")
      render(status: :not_found, json: { success: false }.to_json) && return
    end

    # $2 fee possibly
    if @user.available_budget + 2.to_money < api_params['amount'].to_money
      Airbrake.notify("Can't create Digital Gift, insufficient budget! #{api_params}")
      render(status: :unprocessable_entity, json: { success: false, msg: 'Something has gone wrong, we will be in touch soon: insufficent budget' }.to_json) && return
    end
    #  should check if we've already given a digital gift for this research session
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

    def webhook_params
      params.permit(:payload, :event, :digital_gift)
    end

    def api_params
      params.permit(:person_id,
        :api_token,
        :research_session_id,
        :phone_number,
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

    def valid_request?(request)
      signature_header = request.headers['GiftRocket-Webhook-Signature']
      algorithm, received_signature = signature_header.split('=', 2)

      raise Exception.new('Invalid algorithm') if algorithm != 'sha256'

      expected_signature = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new(algorithm), ENV['GIFT_ROCKET_WEBHOOK'], request.body.read
      )
      received_signature == expected_signature
    end
end
