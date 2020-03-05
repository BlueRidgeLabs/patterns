# frozen_string_literal: true

module SearchHelper
  def search_result_field(value, search_facet = nil)
    Rails.logger.debug("search_result_field: \n\tvalue:#{value}\n\tsearch_facet:#{search_facet}\n\tparams[:#{search_facet}]:#{params[search_facet]}")
    # given a value and an optional search facet, highlight the value in the string
    terms = [params[:q].to_s, params[search_facet].to_s].compact.delete_if(&:blank?)
    Rails.logger.debug("\tterms: #{terms}")
    terms.any? ? highlight(value.to_s, terms) : value
  end

  def action
    if action_name == "advanced_search"
      :post
    else
      :get
    end
  end

  def person_column_headers
    %i[id first_name last_name email_address created updated].freeze
  end

  def person_column_fields
    %i[id first_name last_name email_address created_at updated_at].freeze
  end

  def results_limit
    # max number of search results to display
    10
  end

  def condition_fields
    %w[fields condition].freeze
  end

  def value_fields
    %w[fields value].freeze
  end

  def display_distinct_label_and_check_box
    tag.section do
      check_box_tag(:distinct, "1", user_wants_distinct_results?, class: :cbx) +
        label_tag(:distinct, "Return distinct records")
    end
  end

  def user_wants_distinct_results?
    params[:distinct].to_i == 1
  end

  def display_query_sql(people)
    tag.p("SQL:") + tag.code(people.to_sql)
  end

  def display_sort_column_headers(search)
    person_column_headers.reduce("") do |string, field|
      string << (tag.th sort_link(search, field, {}, method: action))
    end
  end

  def display_search_results(objects)
    objects.limit(results_limit).reduce("") do |string, object|
      string << (tag.tr display_search_results_row(object))
    end
  end

  def display_search_results_row(object)
    person_column_fields.reduce("") do |string, field|
      string << (tag.td object.send(field))
    end
                        .html_safe
  end

  def display_people_comments(comments)
    comments.reduce("") do |string, _post|
      string << (tag.td truncate(comments.title, length: comments_title_length))
    end
            .html_safe
  end
end
