# frozen_string_literal: true

class CacheTagsOnResearchsessions < ActiveRecord::Migration[5.2]
  def change
    add_column :research_sessions, :cached_tag_list, :string
    ResearchSession.reset_column_information
    ActsAsTaggableOn::Taggable::Cache.included(ResearchSession)
    ResearchSession.find_each(batch_size: 1000) do |rs|
      rs.tag_list # it seems you need to do this first to generate the list
      rs.save!
    end
  end
end
