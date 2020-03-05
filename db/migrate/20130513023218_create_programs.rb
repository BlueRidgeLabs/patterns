# frozen_string_literal: true

class CreatePrograms < ActiveRecord::Migration[4.2]
  def change
    create_table :programs do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
