# frozen_string_literal: true

module NameFinderHelper
  def find_name(obj)
    return "None" if obj.nil?
    return obj.name if obj.respond_to?(:name)
    return obj.full_name if obj.respond_to?(:full_name)
    return obj.title if obj.respond_to?(:title)

    obj.class.to_s # last case
  end
end
