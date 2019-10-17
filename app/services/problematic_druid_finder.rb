# frozen_string_literal: true

# Given a list of druids and an ability, returns a list of:
#
# * Druids for objects that the ability cannot manage
# * Druids for objects that are not found
class ProblematicDruidFinder
  # @param [#each] druids a list of druids
  # @param [#can?] ability a cancancan ability
  # @return [Hash] a hash containing not found and/or unauthorized druids
  def self.find(druids:, ability:)
    new(druids: druids, ability: ability).find
  end

  attr_reader :druids, :ability

  # @param [#each] druids a list of druids
  # @param [#can?] ability a cancancan ability
  def initialize(druids:, ability:)
    @druids = druids
    @ability = ability
  end

  # @return [Array] an array of not found druids (an array) and unauthorized druids (an array)
  def find
    not_found_druids = []
    unauthorized_druids = []

    druids.each do |druid|
      current_obj = Dor.find(druid)
      unauthorized_druids << druid unless ability.can?(:manage_item, current_obj)
    rescue ActiveFedora::ObjectNotFoundError
      not_found_druids << druid
    end

    [not_found_druids, unauthorized_druids]
  end
end
