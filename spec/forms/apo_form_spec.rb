require 'spec_helper'

RSpec.describe ApoForm do
  let(:instance) { described_class.new }

  context 'with a model (update)' do
    let(:instance) { described_class.new(apo) }
    let(:agreement) { instantiate_fixture('dd327qr3670', Dor::Item) }
    let(:apo) { instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject) }
    let(:md_info) do
      {
        copyright:    'My copyright statement',
        use:          'My use and reproduction statement',
        title:        'My title',
        desc_md:      'MODS',
        metadata_source: 'DOR',
        agreement:    agreement.pid,
        workflow:     'registrationWF',
        default_object_rights: 'world',
        use_license:  'by-nc'
      }
    end

    before do
      allow(Dor).to receive(:find).with(agreement.pid).and_return(agreement)
    end

    it 'sets clean APO metadata for defaultObjectRights' do
      instance.validate(md_info)
      instance.sync

      expect(apo.mods_title).to           eq(md_info[:title])
      expect(apo.desc_metadata_format).to eq(md_info[:desc_md])
      expect(apo.metadata_source).to      eq(md_info[:metadata_source])
      expect(apo.agreement).to            eq(md_info[:agreement])
      expect(apo.default_workflows).to    eq([md_info[:workflow]])
      expect(apo.default_rights).to       eq(md_info[:default_object_rights])
      expect(apo.use_license).to          eq(md_info[:use_license])
      expect(apo.use_license_uri).to      eq(Dor::Editable::CREATIVE_COMMONS_USE_LICENSES[md_info[:use_license]][:uri])
      expect(apo.use_license_human).to    eq(Dor::Editable::CREATIVE_COMMONS_USE_LICENSES[md_info[:use_license]][:human_readable])
      expect(apo.copyright_statement).to  eq(md_info[:copyright])
      expect(apo.use_statement).to        eq(md_info[:use])
      doc = Nokogiri::XML(File.read('spec/fixtures/apo_defaultObjectRights_clean.xml'))
      expect(apo.defaultObjectRights.content).to be_equivalent_to(doc)
    end

    it 'handles no use license' do
      md_info[:use_license] = ' '
      instance.validate(md_info)
      instance.sync
      expect(apo.use_license).to          be_blank
      expect(apo.use_license_uri).to      be_nil
      expect(apo.use_license_human).to    be_blank
    end
    it 'handles no copyright statement' do
      md_info[:copyright] = ' '
      instance.validate(md_info)
      instance.sync
      expect(apo.copyright_statement).to be_nil
    end
    it 'handles UTF8 copyright statement' do
      md_info[:copyright] = 'Copyright © All Rights Reserved.'
      instance.validate(md_info)
      instance.sync
      expect(apo.copyright_statement).to eq(md_info[:copyright])
    end
    it 'handles no use statement' do
      md_info[:use] = ' '
      instance.validate(md_info)
      instance.sync
      expect(apo.use_statement).to be_nil
    end
    it 'errors out if no workflow' do
      md_info[:workflow] = ' '
      instance.validate(md_info)

      expect { instance.sync }.to raise_error(ArgumentError)
    end

    describe '#permissions' do
      subject { instance.permissions }
      it 'has the defaults' do
        expect(subject).to match_array [
          { name: 'developers', type: 'group', access: 'manage' },
          { name: 'pmag-staff', type: 'group', access: 'manage' },
          { name: 'smpl-staff', type: 'group', access: 'manage' },
          { name: 'dpg-staff', type: 'group', access: 'manage' },
          { name: 'argo-access-spec', type: 'group', access: 'manage' },
          { name: 'lmcrae', type: 'person', access: 'manage' }
        ]
      end
    end

    describe '#default_workflow' do
      subject { instance.default_workflow }
      it { is_expected.to eq 'digitizationWF' }
    end

    describe '#use_license' do
      subject { instance.use_license }
      it { is_expected.to eq 'by-nc-sa' }
    end

    describe '#default_rights' do
      subject { instance.default_rights }
      it { is_expected.to eq 'world' }
    end

    describe '#desc_metadata_format' do
      subject { instance.desc_metadata_format }
      it { is_expected.to eq 'MODS' }
    end
  end

  context 'no model (new)' do
    describe '#permissions' do
      subject { instance.permissions }
      it 'has the defaults' do
        expect(subject).to match_array [
          { name: 'developer', type: 'group', access: 'manage' },
          { name: 'service-manager', type: 'group', access: 'manage' },
          { name: 'metadata-staff', type: 'group', access: 'manage' }
        ]
      end
    end

    describe '#default_workflow' do
      subject { instance.default_workflow }
      it { is_expected.to eq 'registrationWF' }
    end

    describe '#use_license' do
      subject { instance.use_license }
      it { is_expected.to eq '' }
    end

    describe '#default_rights' do
      subject { instance.default_rights }
      it { is_expected.to eq 'world' }
    end

    describe '#desc_metadata_format' do
      subject { instance.desc_metadata_format }
      it { is_expected.to eq 'MODS' }
    end
  end
end
