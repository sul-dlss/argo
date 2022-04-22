# frozen_string_literal: true

module Cocina
  module Models
    class Factories # rubocop:disable Metrics/ClassLength
      module Methods
        def build(type, ...)
          # If we don't support this factory, maybe factory_bot does.
          Factories.supported_type?(type) ? Factories.build(type, ...) : super
        end
      end

      def self.supported_type?(type)
        %i[dro collection admin_policy dro_with_metadata collection_with_metadata admin_policy_with_metadata].include?(type)
      end

      WITH_METADATA_SUFFIX = '_with_metadata'

      def self.build(type, attributes = {})
        raise "Unsupported factory type #{type}" unless supported_type?(type)

        build_type = type.to_s.delete_suffix(WITH_METADATA_SUFFIX)

        fixture = public_send("build_#{build_type}".to_sym, attributes)
        return fixture unless type.ends_with?(WITH_METADATA_SUFFIX)

        Cocina::Models.with_metadata(fixture, 'abc123')
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

      ADMIN_POLICY_DEFAULTS = {
        type: Cocina::Models::ObjectType.admin_policy,
        id: 'druid:bc234fg5678',
        version: 1,
        label: 'test admin policy',
        title: 'test admin policy',
        admin_policy_id: 'druid:hv992ry2431',
        agreement_id: 'druid:hp308wm0436'
      }.freeze

      # rubocop:disable Metrics/ParameterLists
      def self.build_dro_properties(type:, id:, version:, label:, title:, source_id:, admin_policy_id:,
                                    barcode: nil, catkeys: [], collection_ids: [])
        {
          type:,
          externalIdentifier: id,
          version:,
          label:,
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
          if catkeys.present?
            props[:identification][:catalogLinks] = catkeys.map.with_index do |catkey, index|
              { catalog: 'symphony', catalogRecordId: catkey, refresh: index.zero? }
            end
          end
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
          type:,
          externalIdentifier: id,
          version:,
          label:,
          access: {},
          administrative: { hasAdminPolicy: admin_policy_id },
          description: {
            title: [{ value: title }],
            purl: "https://purl.stanford.edu/#{id.delete_prefix('druid:')}"
          },
          identification: {}
        }.tap do |props|
          if catkeys.present?
            props[:identification][:catalogLinks] = catkeys.map.with_index do |catkey, index|
              { catalog: 'symphony', catalogRecordId: catkey, refresh: index.zero? }
            end
          end
          props[:identification][:sourceId] = source_id if source_id
        end
      end
      # rubocop:enable Metrics/ParameterLists

      def self.build_collection(attributes)
        Cocina::Models.build(build_collection_properties(**COLLECTION_DEFAULTS.merge(attributes)))
      end

      def self.build_admin_policy(attributes)
        Cocina::Models.build(build_admin_policy_properties(**ADMIN_POLICY_DEFAULTS.merge(attributes)))
      end

      # rubocop:disable Metrics/ParameterLists
      def self.build_admin_policy_properties(type:, id:, version:, label:, title:,
                                             admin_policy_id:, agreement_id:,
                                             use_statement: nil, copyright: nil, license: nil,
                                             registration_workflow: nil, collections_for_registration: nil)
        {
          type:,
          externalIdentifier: id,
          version:,
          label:,
          administrative: {
            hasAdminPolicy: admin_policy_id,
            hasAgreement: agreement_id,
            accessTemplate: {
              view: 'world',
              download: 'world'
            }
          },
          description: {
            title: [{ value: title }],
            purl: "https://purl.stanford.edu/#{id.delete_prefix('druid:')}"
          }
        }.tap do |props|
          props[:administrative][:accessTemplate][:useAndReproductionStatement] = use_statement if use_statement
          props[:administrative][:accessTemplate][:copyright] = copyright if copyright
          props[:administrative][:accessTemplate][:license] = license if license
          props[:administrative][:registrationWorkflow] = registration_workflow if registration_workflow
          props[:administrative][:collectionsForRegistration] = collections_for_registration if collections_for_registration
        end
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
