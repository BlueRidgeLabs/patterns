# frozen_string_literal: true

class ActivationCallUpdateJob
  include Sidekiq::Worker
  # this needs work.

  def perform(_useless)
    redis = Redis.current
    res = redis.get('ActivationCallUpdateLock')
    if res.nil?
      ActivationCall.ongoing.find_each do |activation_call|
        
        activation_call.call_status = activation_call.call.update.status
        activation_call.save

        if activation_call.card.present?
          if !activation_call.card&.active? && activation_call.timeout_error?
            activation_call.failure
            activation_call.save
          end
          activation_call.update_front_end
          redis.setex('ActivationCallUpdateLock', 5, true)
          sleep 1 unless Rails.env.test?
        else
          # no card associated with this call. do away with it!

          activation_call.destroy if activation_call.call.status == 'completed'
        end
      end until ActivationCall.ongoing.empty?
    end
  end
end
