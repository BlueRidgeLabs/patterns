# frozen_string_literal: true

# Gibbon.api_key = Rails.application.credentials.mailchimp[:api_key]
# Gibbon versions > 0.4.6 below
Gibbon::Request.api_key = Rails.application.credentials.mailchimp[:api_key]
Patterns::Application.config.cut_group_mailchimp_list_id = Rails.application.credentials.mailchimp[:list_id] # the list that we will add all static segements to
