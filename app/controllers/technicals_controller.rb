# frozen_string_literal: true

class TechnicalsController < ApplicationController
  def show
    @techmd = TechmdService.techmd_for(druid: decrypted_token.fetch(:druid))
  end

  private

  # decode the token that grants view access
  # @raise [ActiveSupport::MessageVerifier::InvalidSignature] if the token is invalid
  def decrypted_token
    Argo.verifier.verify(params[:item_id], purpose: :view_token)
  end
end
