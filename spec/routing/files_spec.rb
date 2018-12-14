# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Routing to files' do
  it 'routes to #index' do
    expect(item_files_path(item_id: 'druid:kb487gt5106', id: '0220_MLK_Kids_Gadson_459-25.tif')).to eq '/items/druid:kb487gt5106/files?id=0220_MLK_Kids_Gadson_459-25.tif'
    expect(get: '/items/druid:kb487gt5106/files?id=0220_MLK_Kids_Gadson_459-25.tif').to route_to('controller' => 'files',
                                                                                                 'action' => 'index',
                                                                                                 'item_id' => 'druid:kb487gt5106',
                                                                                                 'id' => '0220_MLK_Kids_Gadson_459-25.tif')
  end

  it 'routes to #show' do
    expect(item_file_path(item_id: 'druid:kb487gt5106', id: '0220_MLK_Kids_Gadson_459-25.tif')).to eq '/items/druid:kb487gt5106/files/0220_MLK_Kids_Gadson_459-25.tif'
    expect(get: '/items/druid:kb487gt5106/files/0220_MLK_Kids_Gadson_459-25.tif').to route_to('controller' => 'files',
                                                                                              'action' => 'show',
                                                                                              'item_id' => 'druid:kb487gt5106',
                                                                                              'id' => '0220_MLK_Kids_Gadson_459-25.tif')
  end

  it 'routes to #preservation' do
    expect(get: '/items/druid:xp320ym6981/files/xp320ym6981_001.tif/preserved?version=1').to route_to('controller' => 'files',
                                                                                                      'action' => 'preserved',
                                                                                                      'item_id' => 'druid:xp320ym6981',
                                                                                                      'id' => 'xp320ym6981_001.tif',
                                                                                                      'version' => '1')
  end
end
