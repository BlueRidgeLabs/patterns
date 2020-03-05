# frozen_string_literal: true

class RenameStatusToCallStatusInActivationCalls < ActiveRecord::Migration[5.2]
  def change
    rename_column :activation_calls, :status, :call_status
  end
end
