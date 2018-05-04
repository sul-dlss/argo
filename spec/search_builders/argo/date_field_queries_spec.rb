require 'spec_helper'

##
# Fake class for testing module
class TestClass
  include Argo::DateFieldQueries
end

describe Argo::DateFieldQueries do
  let(:user) do
    double('user', is_manager?: false, is_admin?: false, is_viewer?: false)
  end
  subject { TestClass.new }

  describe 'add_date_field_queries' do
    describe 'when a date field is faceted' do
      it 'removes the raw fq query in favor of default range query' do
        blacklight_params = { 'f' => { date_field_dt: ['* TO *'] } }
        solr_params = { fq: ['{!term f=date_field_dt}* TO *'] }
        expect(subject).to receive(:blacklight_params)
          .twice.and_return(blacklight_params)
        subject.add_date_field_queries(solr_params)
        expect(solr_params).to eq fq: ['date_field_dt:* TO *']
      end
      it 'does not affect non-date queries' do
        blacklight_params = { 'f' => { title_ssi: ['hello'] } }
        solr_params = { fq: ['{!term f=title_ssi}hello'] }
        expect(subject).to receive(:blacklight_params)
          .twice.and_return(blacklight_params)
        subject.add_date_field_queries(solr_params)
        expect(solr_params).to eq fq: ['{!term f=title_ssi}hello']
      end
    end
  end
end
