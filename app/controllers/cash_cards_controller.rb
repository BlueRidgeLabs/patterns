# frozen_string_literal: true

class CashCardsController < ApplicationController
  before_action :set_cash_card, only: %i[show edit update destroy]

  # GET /cash_cards
  # GET /cash_cards.json
  def index
    if current_user.admin?
      @cash_cards = CashCard.order(id: 'desc').includes(:reward).page(params[:page])
    else
      team_ids = current_user.team.users.map(&:id)
      @cash_cards = CashCard.where(user_id: team_ids).order(id: 'desc').includes(:reward).page(params[:page])
    end
  end

  # GET /cash_cards/1
  # GET /cash_cards/1.json
  def show; end

  # GET /cash_cards/new
  def new
    @cash_card = CashCard.new
  end

  # GET /cash_cards/1/edit
  def edit; end

  # POST /cash_cards
  # POST /cash_cards.json
  def create
    @cash_card = CashCard.new(cash_card_params)

    respond_to do |format|
      if @cash_card.save
        format.html { redirect_to @cash_card, notice: 'Cash card was successfully created.' }
        format.json { render :show, status: :created, location: @cash_card }
      else
        format.html { render :new }
        format.json { render json: @cash_card.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cash_cards/1
  # PATCH/PUT /cash_cards/1.json
  def update
    respond_to do |format|
      if @cash_card.update(cash_card_params)
        format.html { redirect_to @cash_card, notice: 'Cash card was successfully updated.' }
        format.json { render :show, status: :ok, location: @cash_card }
      else
        format.html { render :edit }
        format.json { render json: @cash_card.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cash_cards/1
  # DELETE /cash_cards/1.json
  def destroy
    @cash_card.destroy
    respond_to do |format|
      format.html { redirect_to cash_cards_url, notice: 'Cash card was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_cash_card
    @cash_card = CashCard.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def cash_card_params
    params.fetch(:cash_card, {})
  end
end
