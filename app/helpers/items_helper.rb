# frozen_string_literal: true

module ItemsHelper
  def stacks_url_full_size(druid, filename, user_version: nil)
    # Allow literal slashes in the filename (do not encode them)
    encoded_filename = filename.split('/').map { |filename_part| ERB::Util.url_encode(filename_part) }.join('/')
    return "#{Settings.stacks_version_file_url}/#{druid.delete_prefix('druid:')}/version/#{user_version}/#{encoded_filename}" if user_version

    "#{Settings.stacks_file_url}/#{druid}/#{encoded_filename}"
  end

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

  def license_options
    [['none', '']] + Constants::LICENSE_OPTIONS.map { |attributes| [attributes.fetch(:label), attributes.fetch(:uri)] }
  end
end
