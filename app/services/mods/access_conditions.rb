# frozen_string_literal: true

module Mods
  # Add accessConditions to the public MODS that we publish to PURL.
  # These are derived from the rightsMetadata and are consumed by the
  # Searchworks item view via the mods_display gem.
  class AccessConditions
    # @param [Nokogiri::XML] public_mods
    # @param [Cocina::Models::DroAccess,Cocina::Models::CollectionAccess] access
    def self.add(public_mods:, access:)
      new(public_mods:, access:).add
    end

    def initialize(public_mods:, access:)
      @public_mods = public_mods
      @access = access
    end

    def add
      clear_existing_access_conditions
      add_use_statement
      add_copyright
      add_license
    end

    private

    attr_reader :access, :public_mods

    # clear out any existing accessConditions
    def clear_existing_access_conditions
      public_mods.xpath("//mods:accessCondition", "mods" => ModsService::MODS_NS).each(&:remove)
    end

    def add_use_statement
      add_access_condition(access.useAndReproductionStatement, "useAndReproduction")
    end

    def add_copyright
      add_access_condition(access.copyright, "copyright")
    end

    def add_license
      return unless access.license

      # Add the xlink namespace in case it doesn't exist.  Many items that were
      # Registered via dor-services-app do not because this namespace was not
      # configured here:
      # https://github.com/sul-dlss/dor-services/blob/ef7cd8c8d787e4b9781e5d00282d1d112d0e1f4f/lib/dor/datastreams/desc_metadata_ds.rb#L9-L14
      # We use this namespace when we add accessCondition
      public_mods.root.add_namespace_definition "xlink", "http://www.w3.org/1999/xlink"

      last_element.add_next_sibling public_mods.create_element("accessCondition", license_description,
        :type => "license", "xlink:href" => access.license, :xmlns => ModsService::MODS_NS)
    end

    def license_description
      License.new(url: access.license).description
    end

    def add_access_condition(text, type)
      return if text.blank?

      last_element.add_next_sibling public_mods.create_element("accessCondition", text, type:, xmlns: ModsService::MODS_NS)
    end

    def last_element
      public_mods.root.element_children.last
    end
  end
end
