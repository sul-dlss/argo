# frozen_string_literal: true

class CitationPresenter
  def initialize(document)
    @document = document
  end

  def render
    result = ''
    result += "#{author} " if author.present?
    result += "<em>#{title}</em>" if title.present?
    origin_info = [publisher, place, created_date].compact.join(', ')
    result += ": #{origin_info}" if origin_info.present?
    result.html_safe
  end

  delegate :author, :title, :publisher, :place, :created_date, to: :@document
end
