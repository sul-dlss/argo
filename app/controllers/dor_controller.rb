# frozen_string_literal: true

class DorController < ApplicationController
  # dispatches the reindexing request to the remote reindexing service
  def reindex
    begin
      Dor::Services::Client.object(params[:druid]).reindex
      flash[:notice] = "Successfully updated index for #{params[:druid]}"
    rescue Dor::Services::Client::Error => e
      flash[:error] = "Failed to update index for #{params[:druid]}"
      Rails.logger.error "#{flash[:error]}: #{e.inspect}"
    end

    redirect_back_or_to(
      proc { solr_document_path(params[:druid]) }
    )
  end
end
