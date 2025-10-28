# frozen_string_literal: true

class ReportCategoryComponent < ApplicationComponent
  def initialize(category:)
    @category = category
  end

  attr_reader :category

  def fields
    Report::REPORT_FIELDS_BY_CATEGORY[category]
  end
end
