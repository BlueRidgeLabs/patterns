# frozen_string_literal: true

class AddingRelationshipBetweenProgramsAndApplications < ActiveRecord::Migration[4.2]
  def change
    add_column :applications, :program_id, :integer
  end
end
