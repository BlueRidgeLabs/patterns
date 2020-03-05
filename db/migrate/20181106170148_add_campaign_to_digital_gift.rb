# frozen_string_literal: true

class AddCampaignToDigitalGift < ActiveRecord::Migration[5.2]
  def change
    add_column :digital_gifts, :campaign_id, :string
    add_column :digital_gifts, :campaign_title, :string
    add_column :digital_gifts, :funding_source_id, :string
  end
end
