# frozen_string_literal: true

Redis.current ||= if ENV['REDIS_URL'].blank?
                    Redis.new(host: 'localhost', port: 6379, timeout: 2)
                  else
                    Redis.new(url: ENV['REDIS_URL'], timeout: 2)
                end
