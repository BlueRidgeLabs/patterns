# frozen_string_literal: true

class BudgetsController < ApplicationController
  before_action :admin_needed
  before_action :set_budget, only: %i[show edit update destroy]
  before_action :check_transaction_type, only: :create_transaction
  
  # GET /budgets
  # GET /budgets.json
  def index
    @budgets = Budget.all

    res = DigitalGift.current_budget
    @current_giftrocket_budget = case res
                                 when nil
                                   'Unknown'
                                 else
                                   res.to_s
                                 end
    respond_to do |format|
      format.html
      format.csv do
        send_data TransactionLog.all_csv, filename: 'transactions-all.csv'
      end
    end
  end

  # GET /budgets/1
  # GET /budgets/1.json
  def show
    @transaction_log = TransactionLog.new
    @transactions = @budget.transactions
    respond_to do |format|
      format.html
      format.csv do
        output = CSV.generate do |csv|
          csv << TransactionLog.csv_headers
          @transactions.each { |t| csv << t.to_csv_row }
        end
        send_data output, filename: "transactions-#{@budget.name}.csv"
      end
    end
  end

  # GET /budgets/new
  def new
    @budget = Budget.new
  end

  def create_transaction
    case transaction_log_params[:transaction_type]
    when 'Topup'
      from_type = 'User'
      from_id = current_user.id
      recipient_id = current_user.budget.id
    when 'Transfer'
      from_type = 'Budget'
      recipient_id = transaction_log_params[:recipient_id]
      from_id = transaction_log_params[:from_id].presence || current_user.budget.id
    end

    @transaction_log = TransactionLog.new(amount: transaction_log_params[:amount],
                                          transaction_type: transaction_log_params[:transaction_type],
                                          # all recipients here are budgets. No Digital Gifts
                                          recipient_type: 'Budget',
                                          recipient_id: recipient_id,
                                          from_id: from_id,
                                          from_type: from_type,
                                          user_id: current_user.id)
    respond_to do |format|
      if @transaction_log.save
        flash[:success] = 'Transaction Created'
        format.json { render json: @transaction_log }
      else
        flash[:error] = "Transaction failed: #{@transaction_log.errors.full_messages.join(' ')}"
        format.json { render json: @transaction_log.errors, status: :unprocessable_entity }
      end
      format.js {}
    end
  end

  # GET /budgets/1/edit
  def edit; end

  # POST /budgets
  # POST /budgets.json
  def create
    @budget = Budget.new(budget_params)

    respond_to do |format|
      if @budget.save
        format.html { redirect_to @budget, notice: 'Budget was successfully created.' }
        format.json { render :show, status: :created, location: @budget }
      else
        format.html { render :new }
        format.json { render json: @budget.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /budgets/1
  # PATCH/PUT /budgets/1.json
  def update
    respond_to do |format|
      if @budget.update(budget_params)
        format.html { redirect_to @budget, notice: 'Budget was successfully updated.' }
        format.json { render :show, status: :ok, location: @budget }
      else
        format.html { render :edit }
        format.json { render json: @budget.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /budgets/1
  # DELETE /budgets/1.json
  def destroy
    @budget.destroy
    respond_to do |format|
      format.html { redirect_to budgets_url, notice: 'Budget was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  
  def check_transaction_type
    @transaction_type = transaction_log_params[:transaction_type]
    %w[Transfer Topup].include? @transaction_typez
  end

  def transaction_log_params
    params.permit(:transaction_type, :recipient_id, :from_id, :amount)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_budget
    @budget = Budget.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def budget_params
    params.fetch(:budget, {})
  end
end
