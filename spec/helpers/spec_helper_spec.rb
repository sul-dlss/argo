require 'spec_helper'

describe 'instantiate_fixture' do
  it 'can find fedora_conf documents by druid' do
    @druid = 'rn653dy9317'
    item = instantiate_fixture(@druid, Dor::Item)
    expect(item).to be_instance_of Dor::Item
    expect(item.pid).to eq "druid:#{@druid}"
  end
  it 'can find spec/fixtures documents by druid' do
    @druid = 'zt570tx3016'
    item = instantiate_fixture(@druid, Dor::Item)
    expect(item).to be_instance_of Dor::Item
    expect(item.pid).to eq "druid:#{@druid}"
  end
end
