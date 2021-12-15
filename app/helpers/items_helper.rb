# frozen_string_literal: true

module ItemsHelper
  def stacks_url_full_size(druid, file_name)
    "#{Settings.stacks_file_url}/#{druid}/#{ERB::Util.url_encode(file_name)}"
  end

  # Overriding blacklight so we can pass @techmd to the presenter
  def document_presenter(document)
    super.tap do |presenter|
      # rubocop:disable Rails/HelperInstanceVariable
      presenter.techmd = @techmd if presenter.respond_to? :techmd
      # rubocop:enable Rails/HelperInstanceVariable
    end
  end
end
