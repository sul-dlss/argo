# frozen_string_literal: true

module ItemsHelper
  def stacks_url_full_size(druid, file_name)
    "#{Settings.stacks_file_url}/#{druid}/#{ERB::Util.url_encode(file_name)}"
  end

  # Overriding blacklight so we can pass @cocina to the presenter
  def document_presenter(document)
    super.tap do |presenter|
      presenter.view_token = @verified_token_with_expiration if presenter.respond_to? :view_token
      if presenter.respond_to? :cocina
        presenter.cocina = @cocina
        presenter.state_service = StateService.new(@cocina)
      end
    end
  end

  def license_options
    [["none", ""]] + Constants::LICENSE_OPTIONS.map { |attributes| [attributes.fetch(:label), attributes.fetch(:uri)] }
  end
end
