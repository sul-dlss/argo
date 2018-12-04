# frozen_string_literal: true

##
# Determine user authorization based on index
class PermittedQueries
  include Blacklight::SearchHelper

  attr_reader :groups, :known_roles, :is_admin

  ##
  # @params groups
  # @params [Boolean] is_admin
  # @params [Array<String>] known_roles
  def initialize(groups, known_roles, is_admin)
    @groups = groups
    @known_roles = known_roles
    @is_admin = is_admin
  end

  ##
  # Ported over code from `app/models/user.rb`
  # Also queries Solr based on groups
  # @return [Array[String]] list of DRUIDs from APOs that this User can view
  def permitted_apos
    query = groups.map { |g| RSolr.solr_escape(g) }.join(' OR ')

    q = ''
    if is_admin
      q += '*:*'
    else
      q += 'apo_role_group_manager_ssim:(' + query + ') OR apo_role_person_manager_ssim:(' + query + ')'
      known_roles.each do |role|
        q += ' OR apo_role_' + role + '_ssim:(' + query + ')'
      end
    end

    resp = repository.search(
      q: q,
      defType: 'lucene',
      rows: 1000,
      fl: 'id',
      fq: ['objectType_ssim:adminPolicy', '!project_tag_ssim:Hydrus']
    )['response']['docs']
    resp.map { |doc| doc['id'] }
  end

  ##
  # Ported over code from `app/models/user.rb`
  # Queries Solr yet again! But in a different way! Doesn't use filter query.
  # FIXME: seems to include display logic
  # @return [Array<Array<String>>] Sorted array of pairs of strings, each pair like: ["Title (PID)", "PID"]
  def permitted_collections
    q = if is_admin
          '*:*'
        elsif permitted_apos.empty?
          '-id:*'
        else
          permitted_apos.map { |pid| "#{SolrDocument::FIELD_APO_ID}:\"info:fedora/#{pid}\"" }.join(' OR ')
        end

    result = repository.search(
      q: q,
      defType: 'lucene',
      rows: 1000,
      fl: 'id,sw_display_title_tesim',
      fq: ['objectType_ssim:collection', '!project_tag_ssim:Hydrus']
    )['response']['docs']

    result.sort! do |a, b|
      a['sw_display_title_tesim'].to_s <=> b['sw_display_title_tesim'].to_s
    end

    [['None', '']] + result.map do |doc|
      [Array(doc['sw_display_title_tesim']).first.to_s + ' (' + doc['id'].to_s + ')', doc['id'].to_s]
    end
  end

  private

  def blacklight_config
    @blacklight_config ||= CatalogController.blacklight_config.configure
  end
end
