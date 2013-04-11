module Dor
  module Identifiable
    def to_solr(solr_doc=Hash.new, *args)
      self.assert_content_model
      super(solr_doc)
      solr_doc[Dor::INDEX_VERSION_FIELD] = Dor::VERSION
      solr_doc[solr_name('indexed_at',:date)] = Time.now.utc.xmlschema
      add_solr_value(solr_doc, 'indexed_day', Time.now.beginning_of_day.utc.xmlschema, :string, [:searchable, :facetable])
      datastreams.values.each do |ds|
        unless ds.new?
          add_solr_value(solr_doc,'ds_specs',ds.datastream_spec_string,:string,[:displayable])
        end
      end
      add_solr_value(solr_doc, 'title_sort', self.label, :string, [:sortable])
      rels_doc = Nokogiri::XML(self.datastreams['RELS-EXT'].content)
      collections=rels_doc.search('//rdf:RDF/rdf:Description/fedora:isMemberOfCollection','fedora' => 'info:fedora/fedora-system:def/relations-external#', 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' 	)
      collections.each do |collection_node| 
        druid=collection_node['rdf:resource']
        if(druid)
          druid=druid.gsub('info:fedora/','')
          begin
            collection_object=Dor.find(druid)
            if collection_object.tags.include? 'Project : Hydrus'
              add_solr_value(solr_doc, "hydrus_collection_title", collection_object.label, :string, [:searchable, :facetable])
            else
              add_solr_value(solr_doc, "collection_title", collection_object.label, :string, [:searchable, :facetable])
            end
          rescue
            add_solr_value(solr_doc, "collection_title", druid, :string, [:searchable, :facetable])
          end
        end
      end

      apos=rels_doc.search('//rdf:RDF/rdf:Description/hydra:isGovernedBy','hydra' => 'http://projecthydra.org/ns/relations#', 'fedora' => 'info:fedora/fedora-system:def/relations-external#', 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' 	)
      apos.each do |apo_node|
        druid=apo_node['rdf:resource']
        if druid
          druid=druid.gsub('info:fedora/','')
          begin
            apo_object=Dor.find(druid)
            if apo_object.tags.include? 'Project : Hydrus'
              add_solr_value(solr_doc, "hydrus_apo_title", apo_object.label, :string, [:searchable, :facetable])
            else
              add_solr_value(solr_doc, "apo_title", apo_object.label, :string, [:searchable, :facetable])
            end
          rescue
            add_solr_value(solr_doc, "apo_title", druid, :string, [:searchable, :facetable])
          end
        end
      end
    end 
  end
end
