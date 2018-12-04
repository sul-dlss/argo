# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'files/index.html.erb' do
  let(:contentMetadata) do
    cm = Dor::ContentMetadataDS.new
    cm.content = '<contentMetadata type="image" objectId="rn653dy9317">
  <resource type="image" sequence="106" id="rn653dy9317_106">
    <label>Image 106</label>
    <file mimetype="image/jp2" publish="yes" shelve="yes" format="JPEG2000" preserve="yes" size="3305991" id="M1090_S15_B01_F07_0106.jp2">
      <imageData width="5102" height="3426"/>
      <attr name="representation">uncropped</attr>
      <checksum type="sha1">fd28e74b3139b04a0e5c5c3d3263598f629f8967</checksum>
      <checksum type="md5">244cbb3960407f59ac77a916870e0502</checksum>
    </file>
    <file mimetype="image/tiff" publish="no" shelve="no" format="TIFF" preserve="yes" size="52467428" id="M1090_S15_B01_F07_0106.tif">
      <imageData width="5102" height="3426"/>
      <attr name="representation">uncropped</attr>
      <checksum type="sha1">cf336c4f714b180a09bbfefde159d689e1d517bd</checksum>
      <checksum type="md5">56978088366e66f87d4d5a531f2fea04</checksum>
    </file>
  </resource>
</contentMetadata>'
    cm
  end
  let(:obj) { double(pid: 'druid:rn653dy9317', to_param: 'druid:rn653dy9317', contentMetadata: contentMetadata) }
  it 'renders the partial content' do
    assign(:object, obj)
    assign(:available_in_workspace, true)
    assign(:available_in_workspace_error, nil)
    expect(view).to receive(:params).and_return(file: 'M1090_S15_B01_F07_0106.jp2', id: 'druid:rn653dy9317').at_least(1)
    expect(view).to receive(:has_been_accessioned?).with(obj.pid).and_return(true)
    expect(view).to receive(:last_accessioned_version).with(obj).and_return('1.0.0')

    render

    expect(rendered).to have_css 'div.row[1]', text: 'Workspace'
    expect(rendered).to have_css 'div.row[2]', text: 'Stacks'
    expect(rendered).to have_css 'div.row[3]', text: 'Preservation'
  end
end
