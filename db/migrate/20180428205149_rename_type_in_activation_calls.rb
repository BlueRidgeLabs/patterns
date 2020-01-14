# frozen_string_literal: true

class RenameTypeInActivationCalls < ActiveRecord::Migration[5.2]
  def change
    rename_column :activation_calls, :type, :call_type
  end
end
