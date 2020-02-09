# frozen_string_literal: true

module ApplicationHelper
  delegate :current_cart, to: :current_user

  def nav_bar(classes = "nav")
    content_tag(:ul, class: classes) do
      yield
    end
  end

  def markdown(text)
    options = {
      filter_html: true,
      hard_wrap: true,
      link_attributes: { rel: "nofollow", target: "_blank" },
      space_after_headers: true,
      fenced_code_blocks: true
    }

    extensions = {
      autolink: true,
      superscript: true,
      disable_indented_code_blocks: true
    }

    renderer = Redcarpet::Render::HTML.new(options)
    markdown = Redcarpet::Markdown.new(renderer, extensions)

    markdown.render(text).html_safe
  end

  def nav_link(text, path, options = { class: "" })
    active = current_page?(path) ? "active" : ""
    options[:class] = "nav-item #{active} #{options[:class]}"
    content_tag(:li, options) do
      link_to text, path, { class: "nav-link" }
    end
  end

  # currently busted. gotta figure out why never descending
  def sortable(column, title = nil)
    title ||= column.titleize
    sort_direction = params["direction"]
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, { sort: column, direction: direction }, class: css_class
  end
end
