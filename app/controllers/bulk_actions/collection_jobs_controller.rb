# frozen_string_literal: true

module BulkActions
  class CollectionJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'SetCollectionJob'

    def job_params
      super.merge(new_collection_ids: params[:new_collection_ids].compact_blank)
    end
  end
end
