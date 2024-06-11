# frozen_string_literal: true

class ShowEmbargoComponent < ApplicationComponent
  def initialize(presenter:)
    @solr_document = presenter.document
    @presenter = presenter
  end

  delegate :id, :embargoed?, :embargo_release_date, to: :@solr_document
  delegate :open_and_not_assembling?, to: :@presenter

  def render?
    embargoed? && embargo_release_date.present?
  end

  def edit_embargo
    return unless open_and_not_assembling?

    link_to edit_item_embargo_path(id),
            class: 'text-white',
            aria: { label: 'Manage embargo' },
            data: { controller: 'button', action: 'click->button#open' } do
      tag.span class: 'bi-pencil'
    end
  end
end
