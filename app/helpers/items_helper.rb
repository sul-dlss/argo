# frozen_string_literal: true

module ItemsHelper
  def stacks_url_full_size(druid, file_name)
    "#{Settings.stacks_file_url}/#{druid}/#{ERB::Util.url_encode(file_name)}"
  end
end
