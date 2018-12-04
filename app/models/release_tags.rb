# frozen_string_literal: true

##
# Really at this point, just a way to call and get back an Array of ReleaseTag
class ReleaseTags
  ##
  # @param [Dor::Set, Dor::Collection, Dor::AdminPolicyObject, Dor::Item, Dor::WorkflowObject] object any Dor object that has Identifiable behavior
  # @return [Array<ReleaseTag>]
  def self.from_dor_object(dor_object)
    dor_object.identityMetadata.ng_xml.xpath('//release').map { |tag| ReleaseTag.from_tag(tag) }
  end
end
