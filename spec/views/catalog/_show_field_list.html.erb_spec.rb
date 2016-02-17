require 'spec_helper'

RSpec.describe 'catalog/_show_field_list.html.erb' do
  context 'originInfo_date_created_tesim' do
    let(:field) { 'originInfo_date_created_tesim' }
    let(:label) { 'Created' }
    before(:each) do
      @config = Blacklight::Configuration.new do |config|
        config.add_index_field field, label: label
        config.add_show_field field, :label => label
      end
      allow(view).to receive(:blacklight_config).and_return(@config)
      allow(view).to receive(:field_names).and_return([field])
    end
    def validate_rendering(field_value)
      document = SolrDocument.new(id: 1, field => field_value)
      allow(view).to receive(:document).and_return(document)
      render
      expect(rendered).to have_css ".blacklight-#{field.downcase}"
      expect(rendered).to include label
      expect(rendered).to include field_value.map(&:to_s).join(', ')
    end
    it 'displays a valid field value' do
      field_value = ['1966', '1986']
      validate_rendering(field_value)
    end
    it 'returns "" for nil' do
      field_value = [nil, 'does_not_have_to_be_date_value']
      validate_rendering(field_value)
    end

    context 'when field is metadata_source_ssi' do
      let(:field) { 'metadata_source_ssi' }
      let(:label) { 'MD Source' }

      it 'renders a document with no metadata_source_ssi without crashing' do
        id_metadata = double('identity_metadata')
        mock_obj = double('Dor::Item', { :identityMetadata => id_metadata })
        allow(id_metadata).to receive(:otherId).with('mdtoolkit').and_return(['1']) # Non-zero length array of any value OK
        allow(view).to receive(:object).and_return(mock_obj)
        document = SolrDocument.new(id: 1)
        allow(view).to receive(:document).and_return(document)
        render
        expect(rendered).not_to be_nil
        expect(rendered).to have_css('dt', text: 'MD Source:')
      end
    end
  end
end
