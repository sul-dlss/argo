# frozen_string_literal: true

class EventsController < ApplicationController
  def show
    object_client = Dor::Services::Client.object(decrypted_token.fetch(:druid))
    @events = object_client.events.list
  end

  private

  # decode the token that grants view access
  # @raise [ActiveSupport::MessageVerifier::InvalidSignature] if the token is invalid
  def decrypted_token
    Argo.verifier.verify(params[:item_id], purpose: :view_token)
  end
end
