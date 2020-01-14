# frozen_string_literal: true

class AddDefaultToSubmissionType < ActiveRecord::Migration[4.2]
  def change
    change_column :submissions, :form_type, :integer, default: 0
  end
end
