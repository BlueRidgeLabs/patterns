# frozen_string_literal: true

class ActiveRecord::Base
  def with_user(user)
    self.created_by = user.id if respond_to?(:created_by) && new_record?
    self.updated_by = user.id if respond_to?(:updated_by) && persisted?
    self
  end

  def creator
    User.find created_by if respond_to?(:created_by) && created_by.present?
  end

  def last_updator
    User.find updated_by if respond_to?(:updated_by) && updated_by.present?
  end
end
