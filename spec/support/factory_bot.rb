# frozen_string_literal: true

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    conn = ActiveRecord::Base.connection
    conn.transaction do
      FactoryBot.lint
      raise ActiveRecord::Rollback
    end
  end
end
