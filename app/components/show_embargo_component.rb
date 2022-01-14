# frozen_string_literal: true

class ShowEmbargoComponent < ApplicationComponent
  def initialize(solr_document:)
    @solr_document = solr_document
  end

  delegate :id, :embargoed?, :embargo_release_date, to: :@solr_document

  def render?
    embargoed? && embargo_release_date.present?
  end

  def edit_embargo
    link_to '✎', edit_item_embargo_path(id),
            class: 'text-white',
            aria: { label: 'Manage embargo' },
            data: { controller: 'button', action: 'click->button#open' }
  end
end
