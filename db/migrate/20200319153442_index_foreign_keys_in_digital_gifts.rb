class IndexForeignKeysInDigitalGifts < ActiveRecord::Migration[6.0]
  def change
    add_index :digital_gifts, :gift_id
    add_index :digital_gifts, :person_id
  end
end
