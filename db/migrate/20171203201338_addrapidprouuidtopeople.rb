# frozen_string_literal: true

class Addrapidprouuidtopeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :rapidpro_uuid, :string, unique: true, null: true, default: nil
  end
end
