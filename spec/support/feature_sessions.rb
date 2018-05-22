# frozen_string_literal: true

module Features
  module SessionHelpers
    def sign_in(user = nil, groups: [])
      TestShibbolethHeaders.user = user.login
      TestShibbolethHeaders.groups = groups
    end
  end
end

RSpec.configure do |config|
  config.include Features::SessionHelpers, type: :feature
  config.include Features::SessionHelpers, type: :request
end
