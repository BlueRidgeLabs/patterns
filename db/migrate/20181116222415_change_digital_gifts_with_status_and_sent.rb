# frozen_string_literal: true

class ChangeDigitalGiftsWithStatusAndSent < ActiveRecord::Migration[5.2]
  def change
    rename_column :digital_gifts, :aasm_state, :giftrocket_status
    add_column :digital_gifts, :sent, :boolean
  end
end
