# frozen_string_literal: true

class AddLanguageToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :locale, :string, default: 'en'
  end
end
