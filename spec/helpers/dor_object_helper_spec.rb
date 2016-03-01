require 'spec_helper'
describe DorObjectHelper, :type => :helper do
  describe 'render_status_style' do
    it 'should return the highlighting style for the right status codes' do
      steps = Dor::Processable::STEPS
      highlighted_statuses = [steps['registered'], steps['submitted'], steps['described'], steps['published'], steps['deposited']]

      highlighted_statuses.each do |status_code|
        mock_dor_obj = double(Dor::Processable, :status_info => {:status_code => status_code})
        expect(render_status_style(nil, mock_dor_obj)).to eq('argo-obj-status-highlight')
      end
    end

    it 'should not return the highlighting style for other status codes' do
      steps = Dor::Processable::STEPS
      # note that we omit steps['opened'] because it has the same status code as steps['registered'] and will result in an erroneous test failure
      non_highlighted_statuses = [steps['accessioned'], steps['indexed'], steps['shelved']]

      non_highlighted_statuses.each do |status_code|
        mock_dor_obj = double(Dor::Processable, :status_info => {:status_code => status_code})
        expect(render_status_style(nil, mock_dor_obj)).to eq('')
      end
    end

    it 'should not return the highlighting style for nil objects' do
      expect(render_status_style(nil, nil)).to eq('')
    end
  end

  describe 'get_metadata_source' do
    before :each do
      @id_metadata = double('identity_metadata')
      @mock_obj = double('Dor::Item', { :identityMetadata => @id_metadata })
    end
    it 'should return Metadata Toolkit when identityMetadata.otherId contains mdtoolkit' do
      expect(@id_metadata).to receive(:otherId).with('mdtoolkit').and_return(['1'])
      expect(get_metadata_source(@mock_obj)).to eq('Metadata Toolkit')
    end
    
    it 'should return Symphony when identityMetadata.otherId contains catkey' do
      expect(@id_metadata).to receive(:otherId).with('mdtoolkit').and_return([])
      expect(@id_metadata).to receive(:otherId).with('catkey').and_return(['1'])
      expect(get_metadata_source(@mock_obj)).to eq('Symphony')
    end

    it 'should return DOR when identityMetadata.otherId contains neither mdtoolkit nor catkey' do
      expect(@id_metadata).to receive(:otherId).with('mdtoolkit').and_return([])
      expect(@id_metadata).to receive(:otherId).with('catkey').and_return([])
      expect(get_metadata_source(@mock_obj)).to eq('DOR')
    end
  end
end
