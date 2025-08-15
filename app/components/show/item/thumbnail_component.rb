# frozen_string_literal: true

module Show
  module Item
    class ThumbnailComponent < ApplicationComponent
      def initialize(document:)
        @document = document
      end

      attr_reader :document

      def show_thumbnail?
        document.content_type != 'file' && document.thumbnail_url
      end

      def placeholder_text
        truncate(CitationPresenter.new(document, italicize: false).render, length: 246, omission: '…')
      end
    end
  end
end
