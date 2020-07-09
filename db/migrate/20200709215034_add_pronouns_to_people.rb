class AddPronounsToPeople < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :pronouns, :string, default: 'unknown', null: false
  end
end
