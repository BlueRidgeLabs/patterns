module PeopleHelper
  def private_information(info, name: false)
    if name
      session[:privacy_mode] ? info.initials : info.full_name
    else
      session[:privacy_mode] ? 'hidden' : info
    end
  end
  alias_method :pii, :private_information

  def address_fields_to_sentence(person)
    person.address? ? person.address_fields_to_sentence : 'No address'
  end

  def city_state_to_sentence(person)
    str = [person.city, person.state].reject(&:blank?).join(', ')
    str.empty? ? 'No address' : str
  end
end
