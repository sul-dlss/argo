# frozen_string_literal: true

module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  # Overriding blacklight so we can pass @cocina to the presenter
  def document_presenter(document)
    super.tap do |presenter|
      presenter.view_token = @verified_token_with_expiration if presenter.respond_to? :view_token
      if presenter.respond_to? :cocina
        presenter.cocina = @cocina
        presenter.state_service = StateService.new(@cocina)
        presenter.version_service = VersionService.new(druid: @cocina.externalIdentifier)
        presenter.user_versions_presenter = @user_versions_presenter
        presenter.versions_presenter = @versions_presenter
      end
    end
  end
end
