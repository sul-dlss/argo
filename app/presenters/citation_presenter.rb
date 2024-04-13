# frozen_string_literal: true

class CitationPresenter
  def initialize(document, italicize: true)
    @document = document
    @italicize = italicize
  end

  def render
    result = ''
    result += "#{author} " if author.present?
    if title_display.present?
      result += @italicize ? "<em>#{title_display}</em>" : title_display
    end
    origin_info = [publisher, place, mods_created_date].compact.join(', ')
    result += ": #{origin_info}" if origin_info.present?
    result.html_safe
  end

  delegate :author, :title_display, :publisher, :place, :mods_created_date, to: :@document
end
