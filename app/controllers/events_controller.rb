# frozen_string_literal: true

class EventsController < ApplicationController
  def show
    object_client = Dor::Services::Client.object(decrypted_token.fetch(:key))
    @events = object_client.events.list
  end

  private

  # decode the token that grants view access
  def decrypted_token
    Argo.verifier.verified(params[:item_id], purpose: :view_token)
  end
end
