# a thrown-together (but useful and not overly hacky) one-off script for dumping
# object IDs from solr, to files (json lists), so that other instances can use them for
# reindexing.  good for things like taking known lists from an existing
# prod instance and using them for indexing in an upgraded soon-to-be prod instance.
#
# to use:
# * make sure that BASE_DIR exists relative to where this script is executed
# * make sure OBJ_TYPE_FIELD_NAME is right for the schema of the index you're dumping
# * make sure OBJ_TYPES is the full list of object types you're interested in
# * open rails console on the instance you want to dump from
# * require 'solr_pid_dumper.rb'
# * call Argo::SolrPidDumper.write_solr_pids_by_obj_type
# * use your pids for indexing (e.g., as per https://github.com/sul-dlss/argo/blob/develop/INDEXING.md)

module Argo
  class SolrPidDumper
    OBJ_TYPE_FIELD_NAME = 'objectType_facet'
    OBJ_TYPES = %w{workflow agreement adminPolicy collection set}
    BASE_DIR = 'solr_pid_dumps/'

    def self.solr_pids(q = '*:*')
      puts "querying solr for indexed pids, (q=#{q})..."

      start = 0
      solr_pids = []
      resp = Dor::SearchService.query(q, :sort => 'id asc', :rows => 1000, :start => start, :fl => ['id'])
      while resp.docs.length > 0
          solr_pids += resp.docs.map { |doc| doc['id'] }
          start += 1000
          resp = Dor::SearchService.query(q, :sort => 'id asc', :rows => 1000, :start => start, :fl => ['id'])
        end
      puts "found #{solr_pids.length} pids in solr"
      solr_pids
    end

    def self.write_solr_pids_by_obj_type
      cur_datetime_str = DateTime.now.strftime('%Y-%m-%d_%H:%M:%S')

      pid_lists = {}
      OBJ_TYPES.each do |obj_type|
        obj_type_query = "#{OBJ_TYPE_FIELD_NAME}:\"#{obj_type}\""
        pid_lists[obj_type] = solr_pids obj_type_query

        obj_type_file_name = BASE_DIR + "argo_solr_#{obj_type}_pids_#{cur_datetime_str}.json"
        File.open(obj_type_file_name, 'w') { |file| file.write pid_lists[obj_type].to_json }
        puts "wrote #{obj_type_file_name}"
      end
    end
  end
end
