require 'spec_helper'
describe DorObjectHelper do
  describe 'get_dor_obj_if_exists' do
    it 'should return an object if there is one' do
      obj_id = 'druid:fakedruid'
      mock_dor_obj = double(Dor::Processable)
      Dor.should_receive(:find).with(obj_id).and_return(mock_dor_obj)

      expect(get_dor_obj_if_exists(obj_id)).to eq(mock_dor_obj)
    end

    it 'should return nil if there is no object' do
      obj_id = 'druid:fakedruid'
      Dor.should_receive(:find).with(obj_id).and_raise(ActiveFedora::ObjectNotFoundError)
      expect(get_dor_obj_if_exists(obj_id)).to eq(nil)
    end

    it 'should propogate unexpected errors' do
      obj_id = 'druid:fakedruid'
      Dor.should_receive(:find).with(obj_id).and_raise(StandardError)
      expect { get_dor_obj_if_exists(obj_id) }.to raise_error(StandardError)
    end
  end

  describe 'render_status_style' do
    it 'should return the highlighting style for the right status codes' do
      steps = Dor::Processable::STEPS
      highlighted_statuses = [steps['registered'], steps['submitted'], steps['described'], steps['published'], steps['deposited']]

      mock_dor_obj_list = []
      highlighted_statuses.each do |status_code|
        mock_dor_obj_list << double(Dor::Processable, :status_info => {:status_code => status_code})
      end

      mock_dor_obj_list.each do |mock_dor_obj|
        expect(render_status_style(nil, mock_dor_obj)).to eq("argo-obj-status-highlight")
      end
    end

    it 'should not return the highlighting style for other status codes' do
      steps = Dor::Processable::STEPS
      # note that we omit steps['opened'] because it has the same status code as steps['registered'] and will result in an erroneous test failure
      non_highlighted_statuses = [steps['accessioned'], steps['indexed'], steps['shelved']]

      mock_dor_obj_list = []
      non_highlighted_statuses.each do |status_code|
        mock_dor_obj_list << double(Dor::Processable, :status_info => {:status_code => status_code})
      end

      mock_dor_obj_list.each do |mock_dor_obj|
        expect(render_status_style(nil, mock_dor_obj)).to eq("")
      end
    end

    it 'should not return the highlighting style for nil objects' do
      expect(render_status_style(nil, nil)).to eq("")
    end
  end
end