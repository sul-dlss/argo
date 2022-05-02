# frozen_string_literal: true

# Loads and allows viewing Cocina objects
class CocinaObjectsController < ApplicationController
  # Lazy-load the cocina object part of the show page
  def show
    @cocina_object = Repository.find(decrypted_token.fetch(:key))
  end

  private

  # Decode the token that grants view access
  def decrypted_token
    Argo.verifier.verified(params[:item_id], purpose: :view_token)
  end
end
