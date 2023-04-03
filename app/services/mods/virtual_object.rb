# frozen_string_literal: true

module Mods
  # Service for finding virtual object membership
  class VirtualObject
    # Find virtual objects that this item is a constituent of
    # @param [String] druid
    # @return [Array<Hash>] a list of results with ids and titles
    def self.for(druid:)
      query = "has_constituents_ssim:#{druid.sub(":", '\:')}"
      response = SolrService.get(query, {fl: "id sw_display_title_tesim"})
      response.fetch("response").fetch("docs").map do |row|
        {id: row.fetch("id"), title: row.fetch("sw_display_title_tesim").first}
      end
    end
  end
end
