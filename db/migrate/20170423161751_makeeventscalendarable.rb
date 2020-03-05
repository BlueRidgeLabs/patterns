# frozen_string_literal: true

class Makeeventscalendarable < ActiveRecord::Migration[4.2]
  def change
    rename_column :events, :starts_at, :start_datetime
    rename_column :events, :ends_at, :end_datetime
  end
end
