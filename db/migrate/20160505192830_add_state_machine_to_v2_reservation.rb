# frozen_string_literal: true

class AddStateMachineToV2Reservation < ActiveRecord::Migration[4.2]
  def change
    add_column :v2_reservations, :aasm_state, :string
  end
end
