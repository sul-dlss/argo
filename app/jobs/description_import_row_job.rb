# frozen_string_literal: true

class DescriptionImportRowJob < ApplicationJob
    include Dry::Monads[:result]
  
    ##
    # A job that allows a user to make descriptive updates from a CSV file
    # @param [Integer] bulk_action_id GlobalID for a BulkAction object
    # @param [Hash] params additional parameters that an Argo job may need
    # @option params [String] :csv_file file
    # @option params [String] :csv_filename the name of the file
    def perform(csv_row:, headers:, row_num:, bulk_action:, groups:)
        druid = csv_row.fetch('druid')
        cocina_object = Repository.find(druid)
        BulkJobLog.open(bulk_action.log_name) do |log|
            success = lambda { |message|
            byebug

                bulk_action.with_lock do
                    bulk_action.increment!(:druid_count_success)
                end
                log.puts("Line #{row_num}: #{message} for #{druid} (#{Time.current})")
            }
            failure = lambda { |message|
                bulk_action.with_lock do
                    bulk_action.increment!(:druid_count_fail)
                end
                log.puts("Line #{row_num}: #{message} for #{druid} (#{Time.current})")
            }

            user = bulk_action.user
            # Since a user doesn't persist its groups, we need to pass the groups in here.
            user.set_groups_to_impersonate(groups)
            ability = Ability.new(user)
            return failure.call('Not authorized') unless ability.can?(:update, cocina_object)

            
            DescriptionImport.import(csv_row:, headers:)
                            .bind { |description| validate_changed(cocina_object, description) }
                            .bind { |description| open_version(cocina_object, description, user) }
                            .bind { |description, new_cocina_object| validate_and_save(new_cocina_object, description) }
                            .bind { |new_cocina_object| close_version(new_cocina_object) }
                            .either(
                            ->(_updated) { success.call('Successfully updated') },
                            ->(messages) { failure.call(messages.to_sentence) }
                            )
        rescue => e
            byebug
        end
    end  
  
    private
  
    def validate_changed(cocina_object, description)
      return Failure(['Description unchanged']) if cocina_object.description == description
  
      Success(description)
    end
  
    def open_version(cocina_object, description, user)
      cocina_object = open_new_version_if_needed(cocina_object, 'Descriptive metadata upload', user)
  
      Success([description, cocina_object])
    rescue RuntimeError => e
      Failure([e.message])
    end
  
    def validate_and_save(cocina_object, description)
      result = CocinaValidator.validate_and_save(cocina_object, description:)
      return Success(cocina_object) if result.success?
  
      Failure(["validate_and_save failed for #{cocina_object.externalIdentifier}"])
    end
  
    def close_version(cocina_object)
      VersionService.close(identifier: cocina_object.externalIdentifier) unless StateService.new(cocina_object).object_state == :unlock_inactive
      Success()
    rescue RuntimeError => e
      Failure([e.message])
    end

    # Opens a new minor version of the provided cocina object.
    # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata]
    # @param [String] description for new version
    # @returns [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina object with the new version
    def open_new_version(cocina_object, description, user)
        wf_status = DorObjectWorkflowStatus.new(cocina_object.externalIdentifier, version: cocina_object.version)
        raise 'Unable to open new version' unless wf_status.can_open_version?

        VersionService.open(identifier: cocina_object.externalIdentifier,
                            significance: 'minor',
                            description:,
                            opening_user_name: user.to_s)
    end

    # Opens a new minor version of the provided cocina object unless the object is already open for modification.
    # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata]
    # @param [String] description for new version
    # @returns [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina object with the new/existing version
    def open_new_version_if_needed(cocina_object, description, user)
        state_service = StateService.new(cocina_object)
        return cocina_object if state_service.allows_modification?

        open_new_version(cocina_object, description, user)
    end
end
  