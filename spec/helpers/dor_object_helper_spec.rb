require 'spec_helper'
describe DorObjectHelper, type: :helper do
  describe 'render_status_style' do
    it 'should return the highlighting style for the right status codes' do
      steps = Dor::Processable::STEPS
      highlighted_statuses = [steps['registered'], steps['submitted'], steps['described'], steps['published'], steps['deposited']]

      highlighted_statuses.each do |status_code|
        mock_dor_obj = double(Dor::Processable, status_info: { status_code: status_code })
        expect(render_status_style(nil, mock_dor_obj)).to eq('argo-obj-status-highlight')
      end
    end

    it 'should not return the highlighting style for other status codes' do
      steps = Dor::Processable::STEPS
      # note that we omit steps['opened'] because it has the same status code as steps['registered'] and will result in an erroneous test failure
      non_highlighted_statuses = [steps['accessioned'], steps['indexed'], steps['shelved']]

      non_highlighted_statuses.each do |status_code|
        mock_dor_obj = double(Dor::Processable, status_info: { status_code: status_code })
        expect(render_status_style(nil, mock_dor_obj)).to eq('')
      end
    end

    it 'should not return the highlighting style for nil objects' do
      expect(render_status_style(nil, nil)).to eq('')
    end
  end
end
