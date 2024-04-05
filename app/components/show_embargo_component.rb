# frozen_string_literal: true

class ShowEmbargoComponent < ApplicationComponent
  def initialize(presenter:)
    @solr_document = presenter.document
    @state_service = presenter.state_service
  end

  delegate :id, :embargoed?, :embargo_release_date, to: :@solr_document
  delegate :open?, to: :@state_service

  def render?
    embargoed? && embargo_release_date.present?
  end

  def edit_embargo
    return unless open?

    link_to edit_item_embargo_path(id),
            class: 'text-white',
            aria: { label: 'Manage embargo' },
            data: { controller: 'button', action: 'click->button#open' } do
      tag.span class: 'bi-pencil'
    end
  end
end
