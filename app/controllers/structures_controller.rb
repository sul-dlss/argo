# frozen_string_literal: true

# dispatches to the dor-services-app to (re/un)publish
class StructuresController < ApplicationController
  before_action :load_cocina

  def show
    authorize! :manage_item, @cocina

    respond_to do |format|
      format.csv do
        filename = "structure-#{@cocina.externalIdentifier.delete_prefix('druid:')}.csv"
        send_data StructureSerializer.as_csv(@cocina.structural), filename: filename
      end
    end
  end

  private

  def load_cocina
    @cocina = Dor::Services::Client.object(params[:item_id]).find
  end
end
