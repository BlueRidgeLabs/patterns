class AddMissingIndexes3 < ActiveRecord::Migration[5.2]
  def change
    add_index :versions, [:item_id, :item_type]
  end
end
