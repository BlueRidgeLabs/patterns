class AddUtilizedToEmailLinks < ActiveRecord::Migration[6.0]
  def change
    add_column :email_links, :utilized, :boolean, default: false
  end
end
