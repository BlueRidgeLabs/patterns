# frozen_string_literal: true

json.extract! @mailchimp_update, :raw_content, :email, :update_type, :reason, :fired_at, :created_at, :updated_at
