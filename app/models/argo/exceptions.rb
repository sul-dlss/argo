# frozen_string_literal: true

module Argo
  module Exceptions
    class IndexQueueRequestFailed < StandardError
    end
    class IndexQueueInvalidResponse < StandardError
    end

    # Raised if there is a problem communicating with dor_indexing_app
    class ReindexError < RuntimeError; end
  end
end
