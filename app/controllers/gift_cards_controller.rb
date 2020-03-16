# frozen_string_literal: true

class GiftCardsController < ApplicationController
  before_action :set_gift_card, only: %i[show edit update destroy change_user check]
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :admin_needed, only: %i[preload change_user]
  # GET /gift_cards
  # GET /gift_cards.json
  def index
    @errored_cards = []
    @cards = if current_user.admin?
               GiftCard.includes(:user).unassigned.ready
             else
               GiftCard.includes(:user).unassigned.ready.where(user_id: current_user.id)
    end
    # busted ones first
    @preloaded_cards = GiftCard.includes(:user).preloaded.where(user_id: current_user.id)
    @gift_cards = @cards.sort_by(&:sort_helper)
    @cards = @cards.where(status: 'active')
  end

  def template
    axlsx = Axlsx::Package.new
    wb = axlsx.workbook

    wb.add_worksheet(name: 'CardUploadTemplate') do |sheet|
      sheet.add_row %w[full_card_number sequence_number secure_code batch_id expiration_date amount note]
      sheet.add_row ['4853-9800-6144-1776', '125', '074', '383311', '10/18', '25.00', '<- delete me!'], types: Array.new(7) { :string }
    end

    respond_to do |format|
      format.xlsx do
        response.headers['Content-Type'] = 'text/xlsx'
        response.headers['Content-Disposition'] = 'attachment; filename=GiftCardTemplate.xlsx'
        send_data axlsx.to_stream.read, filename: 'GiftCardTemplate.xlsx'
      end
      format.csv do
        response.headers['Content-Type'] = 'text/xlsx'
        response.headers['Content-Disposition'] = 'attachment; filename=GiftCardTemplate.csv'
        output = CSV.generate do |csv|
          csv << %w[full_card_number expiration_date amount sequence_number secure_code batch_id]
        end
        send_data output, filename: 'GiftCardTemplate.csv'
      end
    end
  end

  def signout_sheet
    gift_cards = if current_user.admin?
                   GiftCard.unassigned.all
                 else
                   current_user.gift_cards.unassigned
    end
    axlsx = Axlsx::Package.new
    wb = axlsx.workbook

    wb.add_worksheet(name: 'Signout Sheet') do |sheet|
      sheet.add_row %w[last_4 sequence_number name email phone zip join_dig?]
      if gift_cards.present?
        gift_cards.each do |card|
          next if card.nil? # WAT?

          sheet.add_row [card.last_4.to_s, card.sequence_number, '', '', '', '', '']
        end
      end
    end

    respond_to do |format|
      format.xlsx do
        response.headers['Content-Type'] = 'text/xlsx'
        response.headers['Content-Disposition'] = 'attachment; filename=GiftCardSignoutSheet.xlsx'
        send_data axlsx.to_stream.read, filename: 'GiftCardSignoutSheet.xlsx'
      end

      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = 'attachment; filename=GiftCardSignoutSheet.csv'
        output = CSV.generate do |csv|
          csv << %w[last_4 sequence_number name email phone zip join_dig?]
          gift_cards.each do |card|
            csv << [card.last_4.to_s, card.sequence_number, '', '', '', '', '']
          end
        end
        send_data output, filename: 'GiftCardSignoutSheet.csv'
      end
    end
  end

  def check
    @gift_card.create_check_call(override: true)
    flash[:notice] = "Checking Card ##{@gift_card.last_4}"
    respond_to do |format|
      format.json { render json: { success: true }, status: :ok }
    end
  end

  # GET /gift_cards/1
  # GET /gift_cards/1.json
  def show; end

  # GET /gift_cards/new
  def new
    @gift_card = GiftCard.new
  end

  # GET /gift_cards/1/edit
  def edit; end

  # assignment happens in gift_card_controller

  def upload
    if params[:file].nil?
      flash[:error] = 'No file uploaded'
    else
      xls = Roo::Spreadsheet.open(params[:file].path)
      cards_count = 0
      xls.sheet(0).each { |row| cards_count += 1 if row[0].present? }
      flash[:notice] = "Import started for #{cards_count - 1} cards."
      @errored_cards = GiftCard.import(params[:file].path, current_user)
      if @errored_cards.present?
        flash[:error] = "Error! #{@errored_cards.size} cards not valid."
      end
    end
    redirect_to gift_cards_path
  end

  def activate
    # iterate through params
    @errors = []

    @gift_cards = new_gift_card_params['new_gift_cards'].map do |ngc|
      next if ngc[:full_card_number].blank? || ngc[:secure_code].blank?

      gc = GiftCard.find_by(sequence_number: ngc[:sequence_number],
                            batch_id: ngc[:batch_id])

      gc.full_card_number = ngc[:full_card_number].delete!('-')
      gc.secure_code = ngc[:secure_code]
      if gc.valid?
        gc.save
        gc.start_activate! if gc.ready!
      else
        Airbrake.notify("Card Error: #{gc.attributes}, #{gc.errors.messages}")
        @errors.push gc.errors.messages[:base]
      end
    end

    respond_to do |format|
      if @errors.empty?
        format.html { redirect_to gift_cards_url, notice: 'Card Activation process started.' }
        format.json { render json: { success: true }, status: :updated }
      else
        flash[:error] = "Card Errors: #{@errors.length} \n #{@errors}"
        format.html { redirect_to gift_cards_url }
        format.json { render json: @errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /gift_cards
  # POST /gift_cards.json
  def create
    # this isn't really used anymore...
    @errors = []
    @gift_cards = new_gift_card_params['new_gift_cards'].map do |ngc|
      GiftCard.new(ngc)
    end

    @gift_cards.each do |gc|
      gc.user = current_user
      gc.scrub_input
      if gc.save
        gc.start_activate!
      else
        Airbrake.notify("Card Error: #{gc.attributes}, #{gc.errors.messages}")
        @errors.push gc.errors.messages[:base]
      end
    end

    # this is where we do the whole starting calls thing.
    # create activation calls type=activate
    # use after_save_commit hook to do background task.
    #
    respond_to do |format|
      if @errors.empty?
        format.html { redirect_to gift_cards_url, notice: 'Card Activation process started.' }
        format.js {}
        format.json { render json: { success: true }, status: :updated }
      else
        flash[:error] = "Card Errors: #{@errors.length} \n #{@errors}"
        format.html { redirect_to gift_cards_url }
        format.json { render json: @errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /gift_cards/1
  # PATCH/PUT /gift_cards/1.json
  def update
    respond_to do |format|
      if @gift_card.update(gift_card_params)
        format.html { redirect_to @gift_card, notice: 'Card activation was successfully updated.' }
        format.json { render :show, status: :ok, location: @gift_card }
      else
        format.html { render :edit }
        format.json { render json: @gift_card.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /gift_cards/1
  # DELETE /gift_cards/1.json
  def destroy
    # TODO: CanCan
    @gift_card.destroy if current_user.admin?
    respond_to do |format|
      if current_user.admin?
        format.html { redirect_to gift_cards_url, notice: 'Card activation was successfully destroyed.' }
        format.json { head :no_content }
      else
        format.json { render json: @gift_card, status: :unauthorized }
        format.html { redirect_to gift_cards_url, notice: 'Not Authorized' }
      end
    end
  end

  def change_user
    # https://stackoverflow.com/questions/18358717/ruby-elegantly-convert-variable-to-an-array-if-not-an-array-already
    ca = Array.wrap(@gift_card)
    ca.each do |c|
      c.user_id = params[:user_id]
      c.save
    end
    flash[:notice] = "#{ca.size} Cards owner changed to #{ca.first.user.name}"
    respond_to do |format|
      format.json { render json: { success: true }.to_json, status: :ok }
    end
  end

  def preload
    gcs = []

    (preload_params[:seq_start]..preload_params[:seq_end]).each do |seq|
      gcs << GiftCard.create(sequence_number: seq.to_i,
                             batch_id: preload_params[:batch_id],
                             amount: preload_params[:amount],
                             expiration_date: preload_params[:expiration_date],
                             user_id: current_user.id,
                             created_by: current_user.id,
                             status: 'preload')
    end
    flash[:notice] = "#{gcs.size} cards added"
    respond_to do |format|
      format.html { redirect_to preloaded_gift_cards_path }
      format.json { render json: { success: true }.to_json, status: :ok }
    end
  end

  # ui for admin card management
  def preloaded
    @preloaded_cards = GiftCard.includes(:user).preloaded.order(sequence_number: :asc).order(batch_id: :desc)
    @low_seq = @preloaded_cards.map(&:sequence_number).map(&:to_i).min
    @high_seq = @preloaded_cards.map(&:sequence_number).map(&:to_i).max
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_gift_card
    ca_id = if params[:id].include? ','
              params[:id].split(',')
            else
              params[:id]
    end

    @gift_card = GiftCard.find(ca_id)
  end

  def preload_params
    params.permit(:seq_start, :seq_end, :batch_id, :amount, :expiration_date)
  end

  def new_gift_card_params
    allowed = %i[amount batch_id expiration_date full_card_number secure_code sequence_number status]
    params.permit(new_gift_cards: allowed)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def gift_card_params
    allowed = %i[amount batch_id expiration_date full_card_number secure_code sequence_number status]

    params.fetch(:gift_card, {}).permit(allowed)
  end
end
