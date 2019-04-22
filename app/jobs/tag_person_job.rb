# # frozen_string_literal: true

# # this was only used for migrating our tags from the old style
# # to acts as taggable. see /lib/tasks/tag_migration.rake
# class TagPersonJob
#   include Sidekiq::Worker
#   sidekiq_options retry: 1

#   def perform(id)
#     Rails.logger.info '[TagPerson] job enqueued'
#     person = Person.find(id)
#     person.tag_list.add(tags)
#     person.save
#   end
# end
