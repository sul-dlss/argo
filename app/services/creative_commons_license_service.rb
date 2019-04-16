# frozen_string_literal: true

class CreativeCommonsLicenseService < Ontology
  # these hashes map short ("machine") license codes to their corresponding URIs and human readable titles. they
  # also allow for deprecated entries (via optional :deprecation_warning).  clients that use these maps are advised to
  # only display undeprecated entries, except where a deprecated entry is already in use by an object.  e.g., an APO
  # that already specifies "by_sa" for its default license code could continue displaying that in a list of license options
  # for editing, preferably with the deprecation warning.  but other deprecated entries would be omitted in such a
  # selectbox.
  @data = {
    'by' => { human_readable: 'Attribution 3.0 Unported',
              uri: 'https://creativecommons.org/licenses/by/3.0/' },
    'by-sa' => { human_readable: 'Attribution Share Alike 3.0 Unported',
                 uri: 'https://creativecommons.org/licenses/by-sa/3.0/' },
    'by_sa' => { human_readable: 'Attribution Share Alike 3.0 Unported',
                 uri: 'https://creativecommons.org/licenses/by-sa/3.0/',
                 deprecation_warning: 'license code "by_sa" was a typo in argo, prefer "by-sa"' },
    'by-nd' => { human_readable: 'Attribution No Derivatives 3.0 Unported',
                 uri: 'https://creativecommons.org/licenses/by-nd/3.0/' },
    'by-nc' => { human_readable: 'Attribution Non-Commercial 3.0 Unported',
                 uri: 'https://creativecommons.org/licenses/by-nc/3.0/' },
    'by-nc-sa' => { human_readable: 'Attribution Non-Commercial Share Alike 3.0 Unported',
                    uri: 'https://creativecommons.org/licenses/by-nc-sa/3.0/' },
    'by-nc-nd' => { human_readable: 'Attribution Non-Commercial, No Derivatives 3.0 Unported',
                    uri: 'https://creativecommons.org/licenses/by-nc-nd/3.0/' },
    'pdm' => { human_readable: 'Public Domain Mark 1.0',
               uri: 'https://creativecommons.org/publicdomain/mark/1.0/' }
  }.freeze
end
