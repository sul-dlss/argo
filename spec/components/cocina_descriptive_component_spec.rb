# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaDescriptiveComponent, type: :component do
  let(:cocina_object) do
    { 'cocinaVersion' => '0.86.0',
      'type' => 'https://cocina.sul.stanford.edu/models/book',
      'externalIdentifier' => 'druid:bb000cr7262',
      'label' => 'Ḥirz-i jān jadīd : yaʻnī k̲h̲ulāṣah Mufīd-i ‘ām',
      'version' => 2,
      'access' =>
      { 'view' => 'stanford',
        'download' => 'none',
        'controlledDigitalLending' => false,
        'copyright' => 'Used under license with Dar ul Ilm.',
        'useAndReproductionStatement' =>
        'Digitized works from the Dar ul Ilm Early South Asian Print collection are licensed through Dar ul Ilm and may be accessed freely by members of the Stanford University community.  These files may not be reproduced or used for any purpose without permission.  To obtain permission to publish or reproduce, please email southasiaref@lists.stanford.edu.' },
      'administrative' => { 'hasAdminPolicy' => 'druid:rs753ms8596' },
      'description' =>
      { 'title' =>
        [{ 'parallelValue' =>
           [{ 'value' => 'Ḥirz-i jān jadīd : yaʻnī k̲h̲ulāṣah Mufīd-i ‘ām',
              'valueLanguage' => { 'valueScript' => { 'code' => 'Latn', 'source' => { 'code' => 'iso15924' } } } },
            { 'value' => 'حرز جان : یعنی خلاصہ مفید عام', 'valueLanguage' => { 'valueScript' => { 'code' => 'Arab', 'source' => { 'code' => 'iso15924' } } } }] }],
        'contributor' =>
        [{ 'name' => [{ 'value' => 'K̲h̲ān, Muḥammad ‘Abdulḥalīm' }],
           'type' => 'person',
           'role' =>
           [{ 'value' => 'author',
              'code' => 'aut',
              'uri' => 'http://id.loc.gov/vocabulary/relators/aut',
              'source' => { 'code' => 'marcrelator', 'uri' => 'http://id.loc.gov/vocabulary/relators/' } }] }],
        'event' =>
        [{ 'date' => [{ 'value' => '1907', 'type' => 'publication', 'status' => 'primary', 'encoding' => { 'code' => 'w3cdtf' } }],
           'location' => [{ 'value' => 'Paṭiyālah' }] },
         { 'location' => [{ 'value' => 'پٹیالہ' }] }],
        'form' =>
        [{ 'value' => 'text', 'type' => 'resource type', 'source' => { 'value' => 'MODS resource types' } },
         { 'value' => 'access', 'type' => 'reformatting quality', 'source' => { 'value' => 'MODS reformatting quality terms' } },
         { 'value' => 'image/jp2', 'type' => 'media type', 'source' => { 'value' => 'IANA media types' } },
         { 'value' => '144, 4 pages', 'type' => 'extent' },
         { 'value' => 'reformatted digital', 'type' => 'digital origin', 'source' => { 'value' => 'MODS digital origin terms' } }],
        'language' =>
        [{ 'code' => 'urd',
           'source' => { 'code' => 'iso639-2b', 'uri' => 'http://id.loc.gov/vocabulary/iso639-2' },
           'uri' => 'http://id.loc.gov/vocabulary/iso639-2/urd',
           'value' => 'Urdu' }],
        'note' =>
        [{ 'value' => 'Ḍākṭar Muḥammad ‘Abdulḥalīm K̲h̲ān',
           'displayLabel' => 'Statement of responsibility',
           'valueLanguage' => { 'valueScript' => { 'code' => 'Latn', 'source' => { 'code' => 'iso15924' } } } },
         { 'value' => 'ڈاکٹر محمد عبدالحلیم خان',
           'displayLabel' => 'Statement of responsibility',
           'valueLanguage' => { 'valueScript' => { 'code' => 'Arab', 'source' => { 'code' => 'iso15924' } } } },
         { 'value' =>
           'Stanford Libraries obtained the best available digital copies and metadata from a third-party vendor who owns the originals. Please be aware that pages may be missing or out of order and some metadata, like dates, might be inaccurate.' }],
        'identifier' => [{ 'value' => '12044', 'type' => 'local', 'source' => { 'code' => 'local' }, 'displayLabel' => 'Sr. No.' }],
        'subject' => [{ 'value' => 'Medicine', 'type' => 'topic' }],
        'access' =>
        { 'accessContact' =>
          [{ 'value' => 'Stanford University. Libraries',
             'type' => 'repository',
             'uri' => 'http://id.loc.gov/authorities/names/n81070667',
             'source' => { 'code' => 'naf' } }] },
        'adminMetadata' =>
        { 'contributor' =>
          [{ 'name' =>
             [{ 'code' => 'CSt',
                'uri' => 'http://id.loc.gov/vocabulary/organizations/cst',
                'source' => { 'code' => 'marcorg', 'uri' => 'http://id.loc.gov/vocabulary/organizations' } }],
             'type' => 'organization',
             'role' => [{ 'value' => 'original cataloging agency' }] }],
          'language' =>
          [{ 'code' => 'eng',
             'script' => { 'value' => 'Latin', 'code' => 'Latn', 'source' => { 'code' => 'iso15924' } },
             'source' => { 'code' => 'iso639-2b', 'uri' => 'http://id.loc.gov/vocabulary/iso639-2' },
             'status' => 'primary',
             'uri' => 'http://id.loc.gov/vocabulary/iso639-2/eng',
             'value' => 'English' }] },
        'purl' => 'https://purl.stanford.edu/bb000cr7262' },
      'identification' => { 'sourceId' => 'esapc:12172' },
      'created' => '2023-11-14T20:39:05.000+00:00',
      'modified' => '2024-06-13T05:11:40.000+00:00',
      'lock' => 'druid:bb000cr7262=0=1' }
  end

  let(:cocina_display) do
    CocinaDisplay::CocinaRecord.new(cocina_object)
  end

  let(:instance) do
    described_class.new(cocina_display:)
  end

  before do
    render_inline(instance)
  end

  it 'renders something useful' do
    expect(page).to have_text 'Ḥirz-i jān jadīd : yaʻnī k̲h̲ulāṣah Mufīd-i ‘ām'
    expect(page).to have_text 'حرز جان : یعنی خلاصہ مفید عام'
    expect(page).to have_text 'K̲h̲ān, Muḥammad ‘Abdulḥalīm'
    expect(page).to have_text 'Urdu'
    expect(page).to have_text 'ڈاکٹر محمد عبدالحلیم خان'
  end
end
