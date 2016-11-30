require 'spec_helper'

RSpec.describe 'catalog/_show_sections/default_contents_external_file.html.erb', type: :view do
  it 'is silent if no resources' do
    render :partial => subject, locals: { resource: Nokogiri::XML('') }
    expect(rendered).to eq('')
  end
  it 'is silent if only file resources' do
    render :partial => subject, locals: { resource: Nokogiri::XML('<file/><file/>') }
    expect(rendered).to eq('')
  end
  it 'shows an external file' do
    render :partial => subject, locals: { resource: Nokogiri::XML('
      <externalFile fileId="2542A.jp2" objectId="druid:cg767mn6478" resourceId="cg767mn6478_1" mimetype="image/jp2"/>') }
    expect(rendered).to have_css('li.external-file span.label', text: 'External File')
    expect(rendered).to have_css('li.external-file', text: '2542A.jp2')
    expect(rendered).to have_css('li.external-file', text: 'from item \'druid:cg767mn6478\'')
    expect(rendered).to have_link('druid:cg767mn6478', href: '/view/druid:cg767mn6478')
    expect(rendered).to have_css('li.external-file', text: 'resource \'cg767mn6478_1\'')
  end
  it 'shows an external file even if it has bad data' do
    render :partial => subject, locals: { resource: Nokogiri::XML('<externalFile fileId="2542A.jp2"/>') }
    expect(rendered).to have_css('li.external-file span.label', text: 'External File')
    expect(rendered).to have_css('li.external-file', text: '2542A.jp2')
    expect(rendered).to have_css('li.external-file', text: 'from item \'\'')
    expect(rendered).to have_css('li.external-file', text: 'resource \'\'')
  end
  it 'shows multiple external files' do
    render :partial => subject, locals: { resource: Nokogiri::XML('<resource>
      <externalFile fileId="2542A.jp2" objectId="druid:cg767mn6478" resourceId="cg767mn6478_1" mimetype="image/jp2"/>
      <externalFile fileId="2542B.jp2" objectId="druid:cg767mn6479" resourceId="cg767mn6479_1" mimetype="image/jp2"/>
      </resource>').children }
    expect(rendered).to have_css('li[1].external-file span.label', text: 'External File')
    expect(rendered).to have_css('li[1].external-file', text: '2542A.jp2')
    expect(rendered).to have_css('li[1].external-file', text: 'from item \'druid:cg767mn6478\'')
    expect(rendered).to have_link('druid:cg767mn6478', href: '/view/druid:cg767mn6478')
    expect(rendered).to have_css('li[1].external-file', text: 'resource \'cg767mn6478_1\'')
    expect(rendered).to have_css('li[2].external-file span.label', text: 'External File')
    expect(rendered).to have_css('li[2].external-file', text: '2542B.jp2')
    expect(rendered).to have_css('li[2].external-file', text: 'from item \'druid:cg767mn6479\'')
    expect(rendered).to have_link('druid:cg767mn6479', href: '/view/druid:cg767mn6479')
    expect(rendered).to have_css('li[2].external-file', text: 'resource \'cg767mn6479_1\'')
  end
end
