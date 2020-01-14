# frozen_string_literal: true

class AddFormIdAndSubmissionTypeToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :form_id, :string
    add_column :submissions, :form_type, :integer
  end
end
