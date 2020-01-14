# frozen_string_literal: true

class ChangeSessionDescriptionToText < ActiveRecord::Migration[5.2]
  def change
    change_column :research_sessions, :description, :text
  end
end
