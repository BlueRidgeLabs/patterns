# frozen_string_literal: true

class Addlocationanddurationtoresearchessions < ActiveRecord::Migration[4.2]
  def change
    add_column :research_sessions, :location, :string
    add_column :research_sessions, :duration, :integer, default: 60
  end
end
