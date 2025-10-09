# frozen_string_literal: true

# Loads and allows viewing Cocina objects
class CocinaObjectsController < ApplicationController
  # Lazy-load the cocina object part of the show page
  def show
    @cocina_object = if user_version
                       Repository.find_user_version(druid, user_version)
                     elsif version
                       Repository.find_version(druid, version)
                     else
                       Repository.find(druid)
                     end
  end

  private

  def druid
    decrypted_token.fetch(:druid)
  end

  def user_version
    decrypted_token[:user_version_id]
  end

  def version
    decrypted_token[:version_id]
  end

  # Decode the token that grants view access
  # @raise [ActiveSupport::MessageVerifier::InvalidSignature] if the token is invalid
  def decrypted_token
    Argo.verifier.verify(params[:item_id], purpose: :view_token)
  end
end
