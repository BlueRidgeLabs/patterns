# frozen_string_literal: true

class ActivationCallUpdateJob
  include Sidekiq::Worker
  # this needs work.
  # should not be a persistent job, should be per call,
  # and should be scheduled in the future to check and cleanup
  # and to do so at intervals

  # this exists because we need to make sure that the call is done
  # and move on to the next check
  def perform(call_id)
    activation_call = ActivationCall.find call_id

    return if activation_call.nil? # what?
    return if activation_call.card.nil? # also wat?
    return if activation_call.card.active? # our work here is done.
    return if activation_call.call_status == "completed"

    # update!
    activation_call.call_status = activation_call.call.update.status
    activation_call.save

    if activation_call.timeout_error?
      activation_call.failure
      activation_call.save
    else
      ActivationCallUpdateJob.perform_in(1.minute, call_id)
    end
  end
end
