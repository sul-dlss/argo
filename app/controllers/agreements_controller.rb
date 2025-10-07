# frozen_string_literal: true

class AgreementsController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', only: :show

  # This is used to draw the name of the agreement on the AdminPolicy show page
  def show
    title = @cocina.description.title.first.value
    render turbo_stream: turbo_stream.update('agreement-title', title)
  end

  def new
    @form = AgreementForm.new
  end

  def create
    @form = AgreementForm.new(agreement_params)
    if @form.validate
      @form.save
      redirect_to solr_document_path(@form.id), notice: 'Agreement created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def agreement_params
    params.expect(agreement: %i[title source_id agreement_file1 agreement_file2])
  end
end
