# frozen_string_literal: true

# Download the CSV descriptive metadata
class DescriptivesController < ApplicationController
  before_action :load_cocina

  def show
    authorize! :manage_item, @cocina

    respond_to do |format|
      format.csv do
        filename = "descriptive-#{Druid.new(@cocina).without_namespace}.csv"
        send_data create_csv, filename: filename
      end
    end
  end

  private

  def load_cocina
    @cocina = Dor::Services::Client.object(params[:item_id]).find
  end

  def create_csv
    description = DescriptionExport.export(source_id: @cocina.identification.sourceId,
                                           description: @cocina.description)
    headers = ['source_id'] + (description.keys - ['source_id']).sort

    CSV.generate(write_headers: true, headers: headers) do |body|
      body << description.values_at(*headers)
    end
  end
end
