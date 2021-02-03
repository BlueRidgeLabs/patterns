# frozen_string_literal: true

require 'aws-sdk-s3'

creds = Aws::Credentials.new(Rails.application.credentials.aws[:api_token],
                             Rails.application.credentials.aws[:api_secret])

Aws.config.update(region: Rails.application.credentials.aws[:region],
                  credentials: creds)
