# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:example, type: :feature) do
    # This stubs out the call that IndexQueue makes
    stub_request(:get, 'https://dor-indexing-app:3000/dor/queue_size.json')
      .to_return(status: 200, body: '1', headers: {})
  end
end
