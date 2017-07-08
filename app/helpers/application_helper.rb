#

module ApplicationHelper
  def simple_time_select_options
    minutes = %w[00 15 30 45]
    hours = (0..23).to_a.map { |h| format('%.2d', h) }
    options = hours.map do |h|
      minutes.map { |m| "#{h}:#{m}" }
    end.flatten
    options_for_select(options)
  end

  def current_cart
    current_user.current_cart(session[:cart_id])
  end

  def nav_bar(classes = 'nav navbar-nav')
    content_tag(:ul, class: classes) do
      yield
    end
  end

  def nav_link(text, path, options = { class: '' })
    options[:class].prepend(current_page?(path) ? 'active ' : '')
    content_tag(:li, options) do
      link_to text, path
    end
  end

  # currently busted. gotta figre out why never descending
  def sortable(column, title = nil)
    title ||= column.titleize
    sort_direction = params['direction']
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title, { sort: column, direction: direction }, { class: css_class }
  end
end
