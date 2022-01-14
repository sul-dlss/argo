# frozen_string_literal: true

class ShowEmbargoComponent < ApplicationComponent
  def initialize(solr_document:)
    @solr_document = solr_document
  end

  delegate :embargoed?, :embargo_release_date, to: :@solr_document

  def render?
    embargoed? && embargo_release_date.present?
  end
end
