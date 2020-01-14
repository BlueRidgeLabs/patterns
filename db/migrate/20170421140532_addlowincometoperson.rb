# frozen_string_literal: true

class Addlowincometoperson < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :low_income, :boolean, null: true
  end
end
