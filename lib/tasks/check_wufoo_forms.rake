# frozen_string_literal: true

namespace :check_wufoo_forms do
  desc 'check wufoo forms for non-GSM characters'
  task badGsmCheck: :environment do
    wufoo = WuParty.new(ENV['WUFOO_ACCOUNT'], ENV['WUFOO_API'])
    forms = wufoo.forms
    forms.each do |form|
      fields = form.flattened_fields
      fields.each do |field|
        title = field['Title']
        canEncode = GSMEncoder.can_encode?(title)
        unless canEncode
          puts title
          puts '-----------'
        end
      end
    end
  end
end
