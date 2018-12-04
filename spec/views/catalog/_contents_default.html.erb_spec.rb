# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'catalog/_contents_default.html.erb', type: :view do
  context 'with files' do
    let(:content_md) do
      Dor::ContentMetadataDS.new.tap do |cm|
        cm.content = <<~XML
          <contentMetadata objectId="bb000zn0114" type="image">
            <resource id="bb000zn0114_1" sequence="1" type="image">
              <label>Image 1</label>
              <file id="PC0062_2008-194_Q03_02_007.jpg" preserve="yes" publish="no" shelve="no" mimetype="image/jpeg" size="1480110">
                <checksum type="md5">8e656c63ea1ad476e515518a46824fac</checksum>
                <checksum type="sha1">0cd3613c7dda558433ad955f0cf4f2730e3ec958</checksum>
                <imageData width="2548" height="1696"/>
              </file>
              <file id="PC0062_2008-194_Q03_02_007.jp2" mimetype="image/jp2" size="819813" preserve="no" publish="yes" shelve="yes">
                <checksum type="md5">1f8d562f4f1fd87946a437176bb8e564</checksum>
                <checksum type="sha1">3206db5137c0820ede261488e08f4d4815d16078</checksum>
                <imageData width="2548" height="1696"/>
              </file>
            </resource>
          </contentMetadata>
        XML
      end
    end
    let(:object) do
      instance_double(Dor::Item,
                      contentMetadata: content_md,
                      to_param: 'druid:bb000zn0114',
                      datastreams: { 'contentMetadata' => content_md })
    end
    let(:solr_doc) do
      SolrDocument.new
    end

    before do
      allow(view).to receive(:can?).and_return(true)
      allow(content_md).to receive(:new?).and_return(false)
    end

    it 'shows multiple external files' do
      render 'catalog/contents_default', object: object, document: solr_doc
      expect(rendered).to have_link('PC0062_2008-194_Q03_02_007.jpg', href: '/items/druid:bb000zn0114/file_list?file=PC0062_2008-194_Q03_02_007.jpg')
      expect(rendered).to have_link('PC0062_2008-194_Q03_02_007.jp2', href: '/items/druid:bb000zn0114/file_list?file=PC0062_2008-194_Q03_02_007.jp2')
    end
  end
end
