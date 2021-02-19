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
      'fa-check text-success'
    elsif !session.can_reward?
      'fa-calendar-times-o text-warning'
    elsif session.can_reward? && !session.complete?
      'fa-times-circle text-danger'
    end
  end

  def session_todo_list(session)
    msgs = []
    msgs << I18n.t('research_session.not_all_invitees_marked') unless session.all_invitees_marked

    msgs << I18n.t('research_session.consent_forms_not_signed', count: session.consent_forms_needed_to_complete) unless session.consent_forms_needed_to_complete.zero?

    msgs << I18n.t('research_session.invitees_not_rewarded', count: session.rewards_needed_to_complete) unless session.rewards_needed_to_complete.zero?
    msgs
  end
end
