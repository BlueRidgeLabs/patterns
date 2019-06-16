# frozen_string_literal: true

class SearchService
  class << self
    def parse_tags(query_params)
      params = Hashie::Mash.new(query_params)
      ransack_tags = params&.ransack_tagged_with || ""
      tag_array = ransack_tags.split(',').map(&:strip)
      Person.active.tag_counts.where(name: tag_array).order(taggings_count: :desc)
    end

    def normalize_query(query_params)
      return unless query_params.present?
      phone = query_params[:phone_number_eq]
      query_params[:phone_number_eq] = PhonyRails.normalize_number(phone) if phone
      active = query_params[:active_eq]
      query_params[:active_eq] = true if active.blank?
      query_params
    end

    def to_csv(query_object)
      results = query_object.result.includes(:tags)
      headers = Person.csv_headers.map(&:titleize)
      CSV.generate do |csv|
        csv << headers
        results.each { |person| csv << person.to_csv_row }
      end
    end
  end
end
