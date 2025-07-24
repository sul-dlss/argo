# frozen_string_literal: true

module Features
  module SessionHelpers
    def sign_in(user = nil, groups: [], example: RSpec.current_example)
      if example.metadata[:type] == :system
        visit auth_test_login_path(remote_user: user.login, groups: groups.join(';'))
      else
        get auth_test_login_path(remote_user: user.login, groups: groups.join(';'))
      end
    end
  end
end

RSpec.configure do |config|
  config.include Features::SessionHelpers, type: :system
  config.include Features::SessionHelpers, type: :request
end
