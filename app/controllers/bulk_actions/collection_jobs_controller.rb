# frozen_string_literal: true

module BulkActions
  class CollectionJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'SetCollectionJob'

    def job_params
      super.merge(new_collection_id: params[:new_collection_id])
    end
  end
end
