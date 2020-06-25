# frozen_string_literal: true

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # Avoid doing this because it registers new items/collections which is slow
  # config.before(:suite) do
  #   FactoryBot.lint
  # end
end
