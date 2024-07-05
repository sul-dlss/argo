# frozen_string_literal: true

module ItemsHelper
  def stacks_url_full_size(druid, filename)
    # Allow literal slashes in the filename (do not encode them)
    encoded_filename = filename.split('/').map { |filename_part| ERB::Util.url_encode(filename_part) }.join('/')
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
        presenter.user_version = @user_version
        presenter.head_user_version = @head_user_version
      end
    end
  end

  def license_options
    [['none', '']] + Constants::LICENSE_OPTIONS.map { |attributes| [attributes.fetch(:label), attributes.fetch(:uri)] }
  end
end
