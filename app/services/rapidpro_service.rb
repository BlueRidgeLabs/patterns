# frozen_string_literal: true

class RapidproService
  class << self
    def language_for_person(person)
      { es: 'spa', zh: 'zho' }[person.locale.to_sym] || 'eng'
    end
  end
end
