# frozen_string_literal: true

module Cocina
  module Models
    class Factories
      module Methods
        def build(type, ...)
          # If we don't support this factory, maybe factory_bot does.
          Factories.supported_type?(type) ? Factories.build(type, ...) : super
        end
      end

      def self.supported_type?(type)
        %i[dro collection].include?(type)
      end

      def self.build(type, attributes = {})
        raise "Unsupported factory type #{type}" unless supported_type?(type)

        public_send("build_#{type}".to_sym, attributes)
      end

      DRO_DEFAULTS = {
        type: Cocina::Models::ObjectType.object,
        id: 'druid:bc234fg5678',
        version: 1,
        label: 'test object',
        title: 'test object',
        source_id: 'sul:1234',
        admin_policy_id: 'druid:hv992ry2431'
      }.freeze

      COLLECTION_DEFAULTS = DRO_DEFAULTS.except(:source_id).merge(type: Cocina::Models::ObjectType.collection)

      # rubocop:disable Metrics/ParameterLists
      def self.build_dro_properties(type:, id:, version:, label:, title:, source_id:, admin_policy_id:,
                                    barcode: nil, catkeys: [], collection_ids: [])
        {
          type: type,
          externalIdentifier: id,
          version: version,
          label: label,
          access: {},
          administrative: { hasAdminPolicy: admin_policy_id },
          description: {
            title: [{ value: title }],
            purl: "https://purl.stanford.edu/#{id.delete_prefix('druid:')}"
          },
          identification: {
            sourceId: source_id
          },
          structural: {
            isMemberOf: collection_ids
          }
        }.tap do |props|
          props[:identification][:catalogLinks] = catkeys.map { |catkey| { catalog: 'symphony', catalogRecordId: catkey } } if catkeys.present?
          props[:identification][:barcode] = barcode if barcode
        end
      end
      # rubocop:enable Metrics/ParameterLists

      def self.build_dro(attributes)
        Cocina::Models.build(build_dro_properties(**DRO_DEFAULTS.merge(attributes)))
      end

      # rubocop:disable Metrics/ParameterLists
      def self.build_collection_properties(type:, id:, version:, label:, title:, admin_policy_id:, source_id: nil, catkeys: [])
        {
          type: type,
          externalIdentifier: id,
          version: version,
          label: label,
          access: {},
          administrative: { hasAdminPolicy: admin_policy_id },
          description: {
            title: [{ value: title }],
            purl: "https://purl.stanford.edu/#{id.delete_prefix('druid:')}"
          },
          identification: {}
        }.tap do |props|
          props[:identification][:catalogLinks] = catkeys.map { |catkey| { catalog: 'symphony', catalogRecordId: catkey } } if catkeys.present?
          props[:identification][:sourceId] = source_id if source_id
        end
      end
      # rubocop:enable Metrics/ParameterLists

      def self.build_collection(attributes)
        Cocina::Models.build(build_collection_properties(**COLLECTION_DEFAULTS.merge(attributes)))
      end
    end
  end
end
