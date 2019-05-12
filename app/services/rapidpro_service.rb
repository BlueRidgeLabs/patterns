class RapidproService
  class << self
    # TODO: test
    def language_for_person(person)
      { es: 'spa', zh: 'chi' }[person.locale.to_sym] || 'eng'
    end
  end
end
