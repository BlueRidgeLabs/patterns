# frozen_string_literal: true

# rubocop:disable ClassLength
class SearchController < ApplicationController

  include PeopleHelper
  include GsmHelper
  include SearchHelper

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength
  def index_ransack
    if params[:q].present? && params[:q][:ransack_tagged_with].present?
      t = params[:q][:ransack_tagged_with].split(',').map(&:strip)
      @tags = Person.active.tag_counts.where(name: t).order(taggings_count: :desc)
    else
      @tags = []
    end

    # normalize phone numbers
    params[:q][:phone_number_eq] = PhonyRails.normalize_number(params[:q][:phone_number_eq]) if params[:q].present? && params[:q][:phone_number_eq].present?

    # allow for larger pages
    Person.per_page = params[:per_page] if params[:per_page].present?

    params[:q][:active_eq] = true if params[:q].present? && params[:q][:active_eq].blank?

    @q = if current_user.admin?
           Person.ransack(params[:q])
         else
           Person.verified.ransack(params[:q])
         end

    @results = @q.result.distinct(:person).includes(:tags).page(params[:page])

    # Need to better define these
    @participation_list = Person.distinct.pluck(:participation_type)
    @verified_list = Person.distinct.pluck(:verified)
    @mailchimp_result = 'Mailchimp export not attempted with this search'

    respond_to do |format|
      format.json { @results }
      format.html do
        if params[:segment_name].present?
          list_name = params.delete(:segment_name)
          @q = Person.active.ransack(params[:q])
          @results_mailchimp = @q.result.includes(:tags)
          @mce = MailchimpExport.new(name: list_name, recipients: @results_mailchimp.collect(&:email_address), created_by: current_user.id)
          if @mce.with_user(current_user).save
            Rails.logger.info("[SearchController#export] Sent #{@mce.recipients.size} email addresses to a static segment named #{@mce.name}")
            @success = "Sent #{@mce.recipients.size} email addresses to a static segment named #{@mce.name}"
            flash[:success] = "Successfully sent to mailchimp: #{@mce.errors.inspect}"
          else
            Rails.logger.error("[SearchController#export] failed to send event to mailchimp: #{@mce.errors.inspect}")
            @error = "failed to send search to mailchimp: #{@mce.errors.inspect}"
            flash[:failure] = "failed to send search to mailchimp: #{@mce.errors.inspect}"
          end
        end
      end
      format.csv do
        if current_user.admin?
          @results = @q.result.includes(:tags)
          fields = Person.column_names
          fields.push('tags')
          output = CSV.generate do |csv|
            # Generate the headers
            csv << fields.map(&:titleize)

            # Some fields need a helper method
            human_devices = %w[primary_device_id secondary_device_id]
            human_connections = %w[primary_connection_id secondary_connection_id]

            # Write the results
            @results.each do |person|
              csv << fields.map do |f|
                field_value = person[f]
                if human_devices.include? f
                  human_device_type_name(field_value)
                elsif human_connections.include? f
                  human_connection_type_name(field_value)
                elsif f == 'phone_number'
                  if field_value.present?
                    field_value.phony_formatted(format: :national, spaces: '-')
                  else
                    ''
                  end
                elsif f == 'tags'
                  if person.tag_values.blank?
                    ''
                  else
                    person.tag_values.join('|')
                  end
                else
                  field_value
                end
              end
            end
          end
          send_data output,  filename: "Search-#{Time.zone.today}.csv"
        else
          flash[:error] = 'Not permitted'
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength

  # FIXME: Refactor and re-enable cop
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  #
  def export_ransack
    list_name = params.delete(:segment_name)
    @q = Person.ransack(params[:q])
    @results = @q.result.includes(:tags)
    @mce = MailchimpExport.new(name: list_name, recipients: @results.collect(&:email_address), created_by: current_user.id)
    if @mce.with_user(current_user).save
      Rails.logger.info("[SearchController#export] Sent #{@mce.recipients.size} email addresses to a static segment named #{@mce.name}")
      respond_to do |format|
        format.js {}
      end
    else
      Rails.logger.error("[SearchController#export] failed to send event to mailchimp: #{@mce.errors.inspect}")
      format.all { render text: "failed to send event to mailchimp: #{@mce.errors.inspect}", status: :bad_request }
    end
  end

  def export
    # send all results to a new static segment in mailchimp
    list_name = params.delete(:segment_name)
    @q = Person.active.ransack(params[:q])
    @people = @q.result.includes(:tags)
    @mce = MailchimpExport.new(name: list_name, recipients: @people.collect(&:email_address), created_by: current_user.id)

    if @mce.with_user(current_user).save
      Rails.logger.info("[SearchController#export] Sent #{@mce.recipients.size} email addresses to a static segment named #{@mce.name}")
      respond_to do |format|
        format.js {}
      end
    else
      Rails.logger.error("[SearchController#export] failed to send event to mailchimp: #{@mce.errors.inspect}")
      format.all { render text: "failed to send event to mailchimp: #{@mce.errors.inspect}", status: :bad_request }
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def add_to_cart
    @q = Person.active.ransack(params[:q])
    pids = current_cart.people_ids
    new_pids = @q.result.map(&:id).delete_if { |i| pids.include?(i) }
    people = Person.find(new_pids)
    flash[:notice] = "adding #{people.size} to pool"
    current_cart.people << people
    flash[:notice] = "#{new_pids.size} people added to #{current_cart.name}."
    respond_to do |format|
      format.js {}
      format.json { render json: { success: true } }
    end
  end

  # FIXME: Refactor and re-enable cop
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Style/MethodName, Style/VariableName
  #
  def exportTwilio
    # send messages to all people
    message1 = params.delete(:message1)
    message2 = params.delete(:message2)
    message1 = GSMEncoder.encode(message1)
    message2 = GSMEncoder.encode(message2) if message2.present?
    messages = Array[message1, message2]
    smsCampaign = params.delete(:twiliowufoo_campaign)
    @q = Person.active.ransack(params[:q])
    @people = @q.result.includes(:tags)
    Rails.logger.info("[SearchController#exportTwilio] people #{@people}")
    phone_numbers = @people.collect(&:phone_number)
    Rails.logger.info("[SearchController#exportTwilio] people #{phone_numbers}")
    phone_numbers = phone_numbers.reject { |e| e.to_s.blank? }

    SendTwilioMessagesJob.perform_async(messages, phone_numbers, smsCampaign)
    Rails.logger.info("[SearchController#exportTwilio] Sent #{phone_numbers} to Twilio")
    respond_to do |format|
      format.js {}
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Style/MethodName, Style/VariableName

  def advanced
    @search = ransack_params
    @search.build_grouping unless @search.groupings.exists?
    @people  = ransack_result
  end

  private

    def ransack_params
      Person.includes(:tags, :comments).ransack(params[:q])
    end

    def ransack_result
      @search.result(distinct: user_wants_distinct_results?)
    end

    # lotta params...
    # rubocop:disable Metrics/MethodLength,
    def index_params
      params.permit(:q,
        :adv,
        :active,
        :first_name,
        :last_name,
        :email_address,
        :postal_code,
        :phone_number,
        :verified,
        :device_description,
        :connection_description,
        :device_id_type,
        :connection_id_type,
        :geography_id,
        :event_id,
        :address,
        :city,
        :tags,
        :preferred_contact_method,
        :page)
    end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable ClassLength
