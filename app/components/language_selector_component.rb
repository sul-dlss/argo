# frozen_string_literal: true

# Show the language selection controls for OCR text extraction workflows
class LanguageSelectorComponent < ApplicationComponent
  def initialize(form:)
    @form = form
  end

  def available_ocr_languages
    ABBYY_LANGUAGES.map { |lang| [lang, lang.gsub(/[ ()]/, '')] }
  end

  attr_reader :form
end
