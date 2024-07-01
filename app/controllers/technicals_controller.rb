# frozen_string_literal: true

class TechnicalsController < ApplicationController
  def show
    @techmd = TechmdService.techmd_for(druid: decrypted_token.fetch(:druid))
  end

  private

  # decode the token that grants view access
  def decrypted_token
    Argo.verifier.verified(params[:item_id], purpose: :view_token)
  end
end
