require 'spec_helper'
describe ArgoHelper do
	describe 'render_document_show_thumbnail' do
		it 'should include a thumbnail url' do
			doc={'shelved_content_file_t'=>'testimage.jp2'}
			link=helper.render_document_show_thumbnail(doc)
			#alt is blank, points to thumb rather than fixed 240x240
			link.should match 'testimage_thumb" style="max-width:240px;max-height:240px;" />'
		end
	end
	describe 'render_index_thumbnail' do
		it 'should include a thumbnail url' do
			doc={'shelved_content_file_t'=>'testimage.jp2'}
			link=helper.render_index_thumbnail(doc)
			#alt is blank, points to thumb rather than fixed sie 80x80 or 240x240
			link.should match 'testimage_thumb" style="max-width:80px;max-height:80px;" />'
		end
		it 'shouldnt return an image tag if the images arent jp2s, because stacks only serves jp2s' do
			doc={'shelved_content_file_t'=>'testimage.tiff'}
			link=helper.render_index_thumbnail(doc)
			link.should == nil
		end
	end
end