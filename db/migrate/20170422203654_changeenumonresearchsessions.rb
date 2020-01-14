# frozen_string_literal: true

class Changeenumonresearchsessions < ActiveRecord::Migration[4.2]
  def change
    rename_column :research_sessions, :type, :session_type
  end
end
