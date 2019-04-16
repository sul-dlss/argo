# frozen_string_literal: true

class OpenDataLicenseService < Ontology
  # these hashes map short ("machine") license codes to their corresponding URIs and human readable titles. they
  # also allow for deprecated entries (via optional :deprecation_warning).  clients that use these maps are advised to
  # only display undeprecated entries, except where a deprecated entry is already in use by an object.  e.g., an APO
  # that already specifies "by_sa" for its default license code could continue displaying that in a list of license options
  # for editing, preferably with the deprecation warning.  but other deprecated entries would be omitted in such a
  # selectbox.
  @data = {
    'pddl' => { human_readable: 'Open Data Commons Public Domain Dedication and License 1.0',
                uri: 'http://opendatacommons.org/licenses/pddl/1.0/' },
    'odc-by' => { human_readable: 'Open Data Commons Attribution License 1.0',
                  uri: 'http://opendatacommons.org/licenses/by/1.0/' },
    'odc-odbl' => { human_readable: 'Open Data Commons Open Database License 1.0',
                    uri: 'http://opendatacommons.org/licenses/odbl/1.0/' }
  }.freeze
end
