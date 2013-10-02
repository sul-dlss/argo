require 'time' 
module Dor  
  module Editable
    def agreement=(val)
      self.agreement_object = Dor::Item.find(val.to_s)
    end
  end
  class IdentityMetadataDS
    def to_solr(solr_doc=Hash.new, *args)
      super(solr_doc, *args)
      if digital_object.respond_to?(:profile)
        digital_object.profile.each_pair do |property,value|
          add_solr_value(solr_doc, property.underscore, value, property =~ /Date/ ? :date : :string, [:searchable])
        end
      end
      if sourceId.present?
        (name,id) = sourceId.split(/:/,2)
        add_solr_value(solr_doc, "dor_id", id, :string, [:searchable])
        add_solr_value(solr_doc, "identifier", sourceId, :string, [:searchable])
        add_solr_value(solr_doc, "source_id", sourceId, :string, [:searchable])
      end
      otherId.compact.each { |qid|
        (name,id) = qid.split(/:/,2)
        add_solr_value(solr_doc, "dor_id", id, :string, [:searchable])
        add_solr_value(solr_doc, "identifier", qid, :string, [:searchable])
        add_solr_value(solr_doc, "#{name}_id", id, :string, [:searchable])
      }
      tag_facet_vals = []
      self.find_by_terms(:tag).each { |tag|
        (top,rest) = tag.text.split(/:/,2)
        unless rest.nil?
          add_solr_value(solr_doc, "#{top.downcase.strip.gsub(/\s/,'_')}_tag", rest.strip, :string, [:searchable, :facetable])
        end
        parts=tag.text.split(/:/)
        partial_tag_states=''
     
        parts.each_with_index do |part, index|
          puts index.to_s + part
          partial_tag_states = part if index == 0
          partial_tag_states += ":"+part if index != 0
          add_solr_value(solr_doc, 'tag', partial_tag_states, :string, [:searchable, :facetable])
        end
      
      }
      solr_doc
    end
  end
end

