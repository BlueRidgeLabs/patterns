# frozen_string_literal: true

class AddTimestampsToV2Reservations < ActiveRecord::Migration[4.2]
  def change
    change_table(:v2_reservations, &:timestamps)
  end
end
