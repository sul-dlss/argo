# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View descriptive metadata' do
  let(:user) { create(:user) }

  let(:cocina_object) do
    build(:dro, id: druid)
  end
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object, user_version: user_version_client, version: version_client) }
  let(:user_version_client) { nil }
  let(:version_client) { nil }
  let(:druid) { 'druid:bc123df4567' }

  let(:mods_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xlink="http://www.w3.org/1999/xlink" version="3.7" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
        <titleInfo>
          <title>PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ.</title>
        </titleInfo>
        <name valueURI="http://id.loc.gov/authorities/names/no2008167343" authority="naf" type="personal">
          <namePart>Scherer, Heinrich, 1628-1704.</namePart>
          <role>
            <roleTerm type="text">creator</roleTerm>
          </role>
        </name>
        <genre authority="marcgt">map</genre>
        <genre>Digital Maps</genre>
        <genre>Early Maps</genre>
        <typeOfResource>cartographic</typeOfResource>
        <physicalDescription>
          <extent>1 map : 23.6 x 35 cm. including border.</extent>
        </physicalDescription>
        <note>California as an island, labelled INS. CALIFORNIA, with interior mountains. North tip labelled NOVA ALBION; other place names include: Hodie (central north), S. Iacob, S. Delphin, S. Nicolas, R. de S. Madalena, S. Bruno, S. Maria de Quadalupe, and C. de S. Lucas. FRETVM ANIAN and Agubela de Gato to north.</note>
        <note>Vignette in lower right depicts Frenchman, Spaniard and an Englishman holding small maps of their respective territories, supported on one side by an Iroquois and on the other by a Huron. Spaniard’s map shows California as an island.</note>
        <note type="publications">From: Geographia politica. Sive historia geographica exhibens totius orbis terraquei status et regimen politicum cum adjectis potissimarum nationum, regnorum ac provinciarum geniis et typis geographicis, Authore P. Henrico Scherer, Societatis Jesu. Pars IV. Sumptibus Joannis Caspari Bencard, Bibliopolæ Academiæ. Monarchii, Typis, Mariæ Magdalenæ Rauchin Viduæ, Anno M.DCCIII. : Atlas Novus exhibens orbem terraqueum per naturæ opera, historiæ novæ ac veteris monumenta, artisque geographicæ leges et præcepta. Hoc est: Geographic universa in septem partes contracta, et instructa ducentis fere chartis geographicis, ac figuris, cujus; Pars IV ... Geographia politica; FOL. Z.Z.; following [p.] 808 and Fol.I.D. Fig.I and Fol.D. 7 parts (pars) published 1702-10; reissued 1730-37. Leighly &amp; Tooley give 1720 date for map.</note>
        <note displayLabel="Statement of responsibility" type="statement of responsibility">[P. Henrico Scherer].</note>
        <note type="references">Tooley 86 (Plate 59), Leighly 151, UCB; Americana Catalogue No. 54, Richard Fitch “Old maps &amp; prints &amp; books”, Item #32.</note>
        <subject>
          <topic>California as an island--Maps</topic>
        </subject>
        <subject>
          <topic>North America--Maps--To 1800</topic>
        </subject>
        <subject>
          <cartographics>
            <scale>[ca.1:26,000,000]</scale>
            <coordinates>W 173° --W 10°/N 84° --N 8°</coordinates>
          </cartographics>
        </subject>
        <originInfo>
          <dateCreated encoding="w3cdtf" keyDate="yes">1703</dateCreated>
          <dateCreated qualifier="inferred" keyDate="yes">1703</dateCreated>
          <place>
            <placeTerm type="text">[Munich]</placeTerm>
          </place>
        </originInfo>
        <identifier displayLabel="Original McLaughlin Book Number (1995 edition)" type="local">160</identifier>
        <location>
          <url usage="primary display">https://purl.stanford.edu/jt667tw2770</url>
        </location>
        <relatedItem type="host">
          <titleInfo>
            <title>The Glen McLaughlin Map Collection of California as an Island</title>
          </titleInfo>
          <location>
            <url>https://purl.stanford.edu/zb871zd0767</url>
          </location>
          <typeOfResource collection="yes"/>
        </relatedItem>
        <accessCondition type="useAndReproduction">Image from the Glen McLaughlin Map Collection of California as an Island courtesy Stanford University Libraries. This item is in the public domain. There are no restrictions on use. If you have questions, please contact the David Rumsey Map Center at rumseymapcenter@stanford.edu.</accessCondition>
        <accessCondition type="copyright">This work has been identified as being free of known restrictions under copyright law, including all related and neighboring rights. You can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission.</accessCondition>
        <accessCondition type="license" xlink:href="https://creativecommons.org/publicdomain/mark/1.0/">This work has been identified as being free of known restrictions under copyright law, including all related and neighboring rights (Public Domain Mark 1.0).</accessCondition>
      </mods>
    XML
  end

  before do
    stub_request(:post, 'https://purl-fetcher.example.edu/v1/mods')
      .to_return(status: 200, body: mods_xml, headers: {})
    sign_in user
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  it 'draws the page' do
    get "/items/#{druid}/metadata/descriptive"
    expect(response).to be_successful
    expect(response.body).to include 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ.'
  end

  context 'when a user version' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, title: 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ.', version: user_version.to_i)
    end
    let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, find: cocina_object) }
    let(:user_version) { '2' }

    it 'displays the user version descriptive metadata' do
      get "/items/#{druid}/user_versions/2/metadata/descriptive"
      expect(response).to be_successful
      expect(response.body).to include 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ.'
      expect(user_version_client).to have_received(:find).with(user_version)
    end
  end

  context 'when a version' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, title: 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ.', version: version.to_i)
    end
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, find: cocina_object) }
    let(:version) { '2' }

    it 'displays the version descriptive metadata' do
      get "/items/#{druid}/version/2/metadata/descriptive"
      expect(response).to be_successful
      expect(response.body).to include 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ.'
      expect(version_client).to have_received(:find).with(version)
    end
  end
end
