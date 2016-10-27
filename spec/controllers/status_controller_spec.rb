require 'spec_helper'

describe StatusController, :type => :controller do
  before :each do
    @druid = 'druid:rn653dy9317'
  end
  describe 'save method' do
    before :each do
      @item = Dor.find(@druid)
      @md = @item.modified_date
    end
    it 'does not alter/save unchanged object' do
      @item.save
      expect(@md).to eq(@item.modified_date)  # changes not visible yet
      @item.reload
      expect(@md).to eq(@item.modified_date)  # changes visible, but there are none
    end
    it 'uses content_will_change! to mark dirty object' do
      @item.identityMetadata.content_will_change!  # mark as dirty
      @item.save
      expect(@md).to be < @item.modified_date
    end
  end
  describe 'log without test_obj' do
    before :each do
      expect(Dor).not_to receive(:find)
    end
    it 'succeeds with recently indexed items' do
      expect(subject).to receive(:check_recently_indexed).and_return(true)
      get 'log'
      expect(response).to have_http_status 200
      expect(response.body).to include 'All good!'
    end
    it 'should 500 with nothing recently indexed' do
      expect(subject).to receive(:check_recently_indexed).and_return(false)
      get 'log'
      expect(response).to have_http_status 500
      expect(response.body).not_to include 'All good!'
      expect(response.body).to include 'Nothing indexed recently'
    end
  end
  describe 'log with test_obj' do
    before :each do
      @item = instantiate_fixture(@druid)
    end
    it 'should 404 instead of 500 on bad IDs' do
      expect(subject).to receive(:check_recently_indexed).and_return(false)
      expect(Dor).to receive(:find).with('junk').and_call_original
      get 'log', :test_obj => 'junk'
      expect(response).to have_http_status 404
    end
    it 'succeeds with recently indexed items' do
      expect(subject).to receive(:check_recently_indexed).and_return(true)
      expect(Dor).not_to receive(:find)
      get 'log', :test_obj => @druid
      expect(response).to have_http_status 200
      expect(response.body).to include 'All good!'
    end
    describe 'with reindexing' do
      before :each do
        expect(Dor).to receive(:find).with(@druid).and_return(@item)
        expect(@item).to receive(:save)
      end
      it 'should 200 after reindexing stale druid' do
        expect(subject).to receive(:check_recently_indexed).and_return(false, true)
        get 'log', :test_obj => @druid, :sleep => 0
        expect(response).to have_http_status 200
        expect(response.body).to include 'All good!'
        expect(response.body).to include "Saved #{@druid}"
      end
      it 'should 500 if reindexing fails' do
        expect(subject).to receive(:check_recently_indexed).and_return(false, false)
        get 'log', :test_obj => @druid, :sleep => 0
        expect(response).to have_http_status 500
        expect(response.body).not_to include 'All good!'
        expect(response.body).to include 'Nothing indexed recently'
      end
    end
  end
end
