# frozen_string_literal: true

module ApplicationHelper
  delegate :current_cart, to: :current_user

  def nav_bar(classes = 'nav', &block)
    tag.ul(class: classes, &block)
  end

  def markdown(text)
    options = {
      filter_html: true,
      hard_wrap: true,
      link_attributes: { rel: 'nofollow', target: '_blank' },
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

  def nav_link(text, path, options = { class: '' })
    active = current_page?(path) ? 'active' : ''
    options[:class] = "nav-item #{active} #{options[:class]}"
    tag.li(options) do
      link_to text, path, { class: 'nav-link' }
    end
  end

  # currently busted. gotta figure out why never descending
  def sortable(column, title = nil)
    title ||= column.titleize
    sort_direction = params['direction']
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title, { sort: column, direction: direction }, class: css_class
  end

  def session_fontawesome_status(session)
    if session.complete?
      "fa-check text-success"
    elsif !session.can_reward?
      "fa-calendar-times-o text-warning"
    elsif session.can_reward? && !session.complete?
      "fa-times-circle text-danger"
    end
  end

  def session_todo_list(session)
    msgs = []

    unless session.all_invitees_marked
      msgs << 'Not all people are marked as Missed or Attended'
    end

    unless session.consent_form_completion_percentage == 1
      msgs << "#{session.consent_form_completion_percentage * 100}% of consent forms signed"
    end

    unless session.reward_completion_percentage
      msgs << "#{session.reward_completion_percentage * 100}% of attended people have a reward"
    end
    msgs
  end
end
