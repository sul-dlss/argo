# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptionHeaders do
  subject(:run) { described_class.create(headers:) }

  let(:source_id) { 'sul:123' }

  let(:headers) do
    %w[adminMetadata.contributor1.name1.code adminMetadata.contributor1.name1.source.code
       adminMetadata.contributor1.role1.value adminMetadata.contributor1.type adminMetadata.event1.date1.encoding.code
       adminMetadata.event1.date1.value adminMetadata.event1.type adminMetadata.event2.date1.encoding.code
       adminMetadata.event2.date1.value adminMetadata.event2.type adminMetadata.identifier1.type
       adminMetadata.identifier1.value adminMetadata.note1.type adminMetadata.note1.value
       contributor1.name1.structuredValue1.type contributor1.name1.structuredValue1.value
       contributor1.name1.structuredValue2.type contributor1.name1.structuredValue2.value contributor1.status
       contributor1.type event1.location1.code contributor1.name1.value contributor1.name10.value contributor1.name2.value
       contributor1.name3.value contributor1.name4.value contributor1.name5.value contributor1.name6.value
       contributor1.name7.value contributor1.name8.value contributor1.name9.value event1.location1.source.code
       event1.note1.source.value event1.note1.type event1.note1.value event2.date1.type event2.date1.value form1.source.value
       form1.type form1.value form2.source.code form2.type form2.value form3.type form3.value language1.code
       language1.source.code note1.type note1.value note2.type note2.value note3.type note3.value note4.type note4.value
       note5.type note5.value note6.type note6.value note7.type note7.value note8.type note8.value note9.type note9.value
       note10.type note10.value note11.type note11.value note12.type note12.value purl
       relatedResource1.contributor1.name1.structuredValue1.type relatedResource1.contributor1.name1.structuredValue1.value
       relatedResource1.contributor1.name1.structuredValue2.type relatedResource1.contributor1.name1.structuredValue2.value
       relatedResource1.contributor1.type relatedResource1.title1.structuredValue1.type
       relatedResource1.title1.structuredValue1.value relatedResource1.title1.structuredValue2.type
       relatedResource1.title1.structuredValue2.value source_id subject1.source.code subject1.structuredValue1.type
       subject1.structuredValue1.value subject1.structuredValue2.type subject1.structuredValue2.value title1.note1.value
       title1.note1.type title1.structuredValue1.type title1.structuredValue1.value title1.structuredValue2.type
       title1.structuredValue2.value title1.value title1.type title2.structuredValue1.type title2.structuredValue1.value
       title2.structuredValue2.structuredValue1.type title2.structuredValue2.structuredValue1.value
       title2.structuredValue2.structuredValue2.type title2.structuredValue2.structuredValue2.value
       title2.structuredValue2.type title2.type].freeze
  end

  let(:expected_headers) do
    %w[source_id title1.note1.type title1.note1.value title1.structuredValue1.type
       title1.structuredValue1.value title1.structuredValue2.type title1.structuredValue2.value title1.type title1.value
       title2.structuredValue1.type title2.structuredValue1.value title2.structuredValue2.structuredValue1.type
       title2.structuredValue2.structuredValue1.value title2.structuredValue2.structuredValue2.type
       title2.structuredValue2.structuredValue2.value title2.structuredValue2.type title2.type
       contributor1.name1.structuredValue1.type contributor1.name1.structuredValue1.value
       contributor1.name1.structuredValue2.type contributor1.name1.structuredValue2.value
       contributor1.name1.value contributor1.name2.value contributor1.name3.value contributor1.name4.value
       contributor1.name5.value contributor1.name6.value contributor1.name7.value contributor1.name8.value
       contributor1.name9.value contributor1.name10.value contributor1.status
       contributor1.type form1.source.value form1.type form1.value form2.source.code form2.type form2.value form3.type
       form3.value event1.location1.code event1.location1.source.code event1.note1.source.value event1.note1.type
       event1.note1.value event2.date1.type event2.date1.value language1.code language1.source.code note1.type note1.value
       note2.type note2.value note3.type note3.value note4.type note4.value note5.type note5.value note6.type note6.value
       note7.type note7.value note8.type note8.value note9.type note9.value note10.type note10.value note11.type note11.value
       note12.type note12.value purl subject1.source.code subject1.structuredValue1.type subject1.structuredValue1.value
       subject1.structuredValue2.type subject1.structuredValue2.value
       relatedResource1.contributor1.name1.structuredValue1.type relatedResource1.contributor1.name1.structuredValue1.value
       relatedResource1.contributor1.name1.structuredValue2.type relatedResource1.contributor1.name1.structuredValue2.value
       relatedResource1.contributor1.type relatedResource1.title1.structuredValue1.type
       relatedResource1.title1.structuredValue1.value relatedResource1.title1.structuredValue2.type
       relatedResource1.title1.structuredValue2.value adminMetadata.contributor1.name1.code
       adminMetadata.contributor1.name1.source.code adminMetadata.contributor1.role1.value adminMetadata.contributor1.type
       adminMetadata.event1.date1.encoding.code adminMetadata.event1.date1.value adminMetadata.event1.type
       adminMetadata.event2.date1.encoding.code adminMetadata.event2.date1.value adminMetadata.event2.type
       adminMetadata.identifier1.type adminMetadata.identifier1.value adminMetadata.note1.type
       adminMetadata.note1.value].freeze
  end

  it 'orders the headers' do
    expect(run).to eq(expected_headers)
  end
end
