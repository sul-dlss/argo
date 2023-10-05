# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileHierarchyService do
  subject(:root_directory) { described_class.to_hierarchy(cocina_object:) }

  let(:cocina_object) { instance_double(Cocina::Models::DRO, structural:) }

  let(:file1) do
    Cocina::Models::File.new(
      {
        type: Cocina::Models::ObjectType.file,
        externalIdentifier: 'https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd',
        label: 'bb045jk9908_0001.tiff',
        filename: 'bb045jk9908_0001.tiff',
        size: 22_454_748,
        version: 1,
        hasMimeType: 'image/tiff',
        hasMessageDigests: [
          {
            type: 'sha1',
            digest: 'ff66b3b3dc3ef733d39e949549791ff78754871b'
          },
          {
            type: 'md5',
            digest: 'b6ce12a1dd5db09f10b51659c83f90a3'
          }
        ],
        access: {
          view: 'world',
          download: 'world'
        },
        administrative: {
          publish: false,
          sdrPreserve: true,
          shelve: false
        },
        presentation: {
          height: 5833,
          width: 4001
        }
      }
    )
  end

  let(:file2) do
    Cocina::Models::File.new(
      {
        type: Cocina::Models::ObjectType.file,
        externalIdentifier: 'https://cocina.sul.stanford.edu/file/92db9253-19b7-4092-b472-6e73f3c2251e',
        label: 'bb045jk9908_0001.jp2',
        filename: 'bb045jk9908_0001.jp2',
        size: 4_379_498,
        version: 1,
        hasMimeType: 'image/jp2',
        hasMessageDigests: [
          {
            type: 'sha1',
            digest: '9fafbab8986cea0c70bb0aacc9ce282482cad22e'
          },
          {
            type: 'md5',
            digest: '1633661828d894cdaa79f5549f0cd025'
          }
        ],
        access: {
          view: 'location-based',
          download: 'location-based',
          location: 'music'
        },
        administrative: {
          publish: true,
          sdrPreserve: false,
          shelve: true
        },
        presentation: {
          height: 5833,
          width: 4001
        }
      }
    )
  end

  let(:file3) do
    {
      type: Cocina::Models::ObjectType.file,
      externalIdentifier: 'https://cocina.sul.stanford.edu/file/86de37bc-b930-49ac-936b-15e8db7af88e',
      label: 'bb045jk9908_0002.tiff',
      filename: 'dir1/bb045jk9908_0002.tiff',
      size: 19_962_338,
      version: 1,
      hasMimeType: 'image/tiff',
      hasMessageDigests: [
        {
          type: 'sha1',
          digest: 'a6a8e34aaafb8b11e5b06749ad5e7c9879b81850'
        },
        {
          type: 'md5',
          digest: '62f0228e64728a2b28dd960910cf88bd'
        }
      ],
      access: {
        view: 'world',
        download: 'world'
      },
      administrative: {
        publish: false,
        sdrPreserve: true,
        shelve: false
      },
      presentation: {
        height: 5833,
        width: 4001
      }
    }
  end

  let(:file4) do
    {
      type: Cocina::Models::ObjectType.file,
      externalIdentifier: 'https://cocina.sul.stanford.edu/file/55d78b7f-b043-4880-8542-b85f2c3b0414',
      label: 'bb045jk9908_0002.jp2',
      filename: 'dir1/bb045jk9908_0002.jp2',
      size: 4_391_262,
      version: 1,
      hasMimeType: 'image/jp2',
      hasMessageDigests: [
        {
          type: 'sha1',
          digest: '5681fd7d546f436aab183e2e7ed82a15e90d71ce'
        },
        {
          type: 'md5',
          digest: '3aaad28b903831983e6714269f10f9b1'
        }
      ],
      access: {
        view: 'world',
        download: 'world'
      },
      administrative: {
        publish: true,
        sdrPreserve: false,
        shelve: true
      },
      presentation: {
        height: 5833,
        width: 4001
      }
    }
  end

  let(:file5) do
    {
      type: Cocina::Models::ObjectType.file,
      externalIdentifier: 'https://cocina.sul.stanford.edu/file/55d78b7f-b043-4880-8542-b85f2c3b0414',
      label: 'bb045jk9908_0003.jp2',
      filename: 'dir1/dir2/bb045jk9908_0003.jp2',
      size: 5_391_263,
      version: 1,
      hasMimeType: 'image/jp2',
      hasMessageDigests: [
        {
          type: 'sha1',
          digest: '5681fd7d546f436aab183e2e7ed82a15e90d71ce'
        },
        {
          type: 'md5',
          digest: '3aaad28b903831983e6714269f10f9b1'
        }
      ],
      access: {
        view: 'world',
        download: 'world'
      },
      administrative: {
        publish: true,
        sdrPreserve: false,
        shelve: true
      },
      presentation: {
        height: 5833,
        width: 4001
      }
    }
  end

  let(:structural) do
    Cocina::Models::DROStructural.new(
      contains: [
        {
          type: Cocina::Models::FileSetType.image,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23',
          label: 'Image 1',
          version: 1,
          structural: {
            contains: [
              file1,
              file2
            ]
          }
        },
        {
          type: Cocina::Models::FileSetType.image,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/a45774e4-ac26-425a-b40e-f5e247135843',
          label: 'Image 2',
          version: 1,
          structural: {
            contains: [
              file3,
              file4
            ]
          }
        },
        {
          type: Cocina::Models::FileSetType.image,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/a45774e4-ac26-425a-b40e-f5e247135854',
          label: 'Image 3',
          version: 1,
          structural: {
            contains: [
              file5
            ]
          }
        }
      ]
    )
  end

  it 'returns a hash of the file hierarchy' do
    expect(root_directory).to match(
      FileHierarchyService::Directory.new('', [
                                            FileHierarchyService::Directory.new('dir1', [
                                                                                  FileHierarchyService::Directory.new('dir2', [], [
                                                                                                                        FileHierarchyService::File.new('bb045jk9908_0003.jp2', 5_391_263)
                                                                                                                      ], 3)
                                                                                ], [
                                                                                  FileHierarchyService::File.new(
                                                                                    'bb045jk9908_0002.tiff', 19_962_338
                                                                                  ),
                                                                                  FileHierarchyService::File.new(
                                                                                    'bb045jk9908_0002.jp2', 4_391_262
                                                                                  )
                                                                                ], 2)
                                          ], [
                                            FileHierarchyService::File.new('bb045jk9908_0001.tiff', 22_454_748),
                                            FileHierarchyService::File.new('bb045jk9908_0001.jp2', 4_379_498)
                                          ], 1)
    )
  end
end
