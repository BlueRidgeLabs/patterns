# frozen_string_literal: true

class CacheTagsOnPeopleAndUuidCart < ActiveRecord::Migration[5.2]
  def change
    add_column :carts, :rapidpro_uuid, :string, unique: true, null: true, default: nil
    add_column :people, :cached_tag_list, :text
    Person.reset_column_information
    ActsAsTaggableOn::Taggable::Cache.included(Person)
    Person.find_each(batch_size: 1000) do |person|
      person.tag_list # it seems you need to do this first to generate the list
      person.save!
    end
  end
end
