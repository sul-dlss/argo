# frozen_string_literal: true

class AgreementsController < ApplicationController
  def new
    @form = AgreementForm.new(nil)
  end

  def create
    @form = AgreementForm.new(nil)
    if @form.validate(params[:agreement]) && @form.save
      redirect_to solr_document_path(@form.model.externalIdentifier), notice: 'Agreement created.'
    else
      render :new
    end
  end
end
