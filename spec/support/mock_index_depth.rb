# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:example, type: :feature) do
    # This stubs out the call that IndexQueue makes
    stub_request(:get, 'https://status.example.com/render/?format=json&other=params')
      .to_return(status: 200, body: '1', headers: {})
  end
end
