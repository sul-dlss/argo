# frozen_string_literal: true

##
# A module for including constants throughout the Argo application
module Constants
  COLLECTION_RIGHTS_OPTIONS = [
    %w[World world],
    ["Dark (Preserve Only)", "dark"]
  ].freeze

  VIEW_ACCESS_OPTIONS = %w[world stanford location-based citation-only dark].freeze
  DOWNLOAD_ACCESS_OPTIONS = %w[world stanford location-based none].freeze
  ACCESS_LOCATION_OPTIONS = %w[spec music ars art hoover m&m].freeze
  CDL_OPTIONS = [true, false].freeze

  LICENSE_OPTIONS = [
    # CC4 licenses
    {label: "CC Attribution 4.0 International",
     uri: "https://creativecommons.org/licenses/by/4.0/legalcode",
     code: "CC-BY-4.0"},
    {label: "CC Attribution-NonCommercial 4.0 International",
     uri: "https://creativecommons.org/licenses/by-nc/4.0/legalcode",
     code: "CC-BY-NC-4.0"},
    {label: "CC Attribution-NonCommercial, No Derivatives 4.0 International",
     uri: "https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode",
     code: "CC-BY-NC-ND-4.0"},
    {label: "CC Attribution-NonCommercial Share Alike 4.0 International",
     uri: "https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode",
     code: "CC-BY-NC-SA-4.0"},
    {label: "CC Attribution-NoDerivatives 4.0 International",
     uri: "https://creativecommons.org/licenses/by-nd/4.0/legalcode",
     code: "CC-BY-ND-4.0"},
    {label: "CC Attribution-ShareAlike 4.0 International",
     uri: "https://creativecommons.org/licenses/by-sa/4.0/legalcode",
     code: "CC-BY-SA-4.0"},
    {label: "CC Zero 1.0",
     uri: "https://creativecommons.org/publicdomain/zero/1.0/legalcode",
     code: "CC0-1.0"},
    # ODC licenses
    {label: "Open Data Commons Attribution License 1.0",
     uri: "https://opendatacommons.org/licenses/by/1-0/",
     code: "ODC-By-1.0"},
    {label: "Open Data Commons Open Database License 1.0",
     uri: "https://opendatacommons.org/licenses/odbl/1-0/",
     code: "ODbL-1.0"},
    {label: "Open Data Commons Public Domain Dedication and License 1.0",
     uri: "https://opendatacommons.org/licenses/pddl/1-0/",
     code: "PDDL-1.0"},
    # OSS licenses
    {label: "AGPL-3.0-only GNU Affero General Public License",
     uri: "https://www.gnu.org/licenses/agpl.txt",
     code: "AGPL-3.0-only"},
    {label: "Apache-2.0",
     uri: "https://www.apache.org/licenses/LICENSE-2.0",
     code: "Apache-2.0"},
    {label: "BSD-2-Clause 'Simplified' License",
     uri: "https://opensource.org/licenses/BSD-2-Clause",
     code: "BSD-2-Clause"},
    {label: "BSD-3-Clause 'New' or 'Revised' License",
     uri: "https://opensource.org/licenses/BSD-3-Clause",
     code: "BSD-3-Clause"},
    {label: "CDDL-1.1 Common Development and Distribution License",
     uri: "https://opensource.org/licenses/cddl1",
     code: "CDDL-1.1"},
    {label: "EPL-2.0 Eclipse Public License",
     uri: "https://www.eclipse.org/legal/epl-2.0",
     code: "EPL-2.0"},
    {label: "GPL-3.0-only GNU General Public License",
     uri: "https://www.gnu.org/licenses/gpl-3.0-standalone.html",
     code: "GPL-3.0-only"},
    {label: "ISC License",
     uri: "https://www.isc.org/downloads/software-support-policy/isc-license/",
     code: "ISC"},
    {label: "LGPL-3.0-only Lesser GNU Public License",
     uri: "https://www.gnu.org/licenses/lgpl-3.0-standalone.html",
     code: "LGPL-3.0-only"},
    {label: "MIT License",
     uri: "https://opensource.org/licenses/MIT",
     code: "MIT"},
    {label: "MPL-2.0 Mozilla Public License",
     uri: "https://www.mozilla.org/MPL/2.0/",
     code: "MPL-2.0"},
    # CC3 licenses
    {label: "CC Attribution 3.0 Unported",
     uri: "https://creativecommons.org/licenses/by/3.0/legalcode",
     code: "CC-BY-3.0"},
    {label: "CC Attribution Non-Commercial 3.0 Unported",
     uri: "https://creativecommons.org/licenses/by-nc/3.0/legalcode",
     code: "CC-BY-NC-3.0"},
    {label: "CC Attribution Non-Commercial, No Derivatives 3.0 Unported",
     uri: "https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode",
     code: "CC-BY-NC-ND-3.0"},
    {label: "CC Attribution Non-Commercial Share Alike 3.0 Unported",
     uri: "https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode",
     code: "CC-BY-NC-SA-3.0"},
    {label: "CC Attribution No Derivatives 3.0 Unported",
     uri: "https://creativecommons.org/licenses/by-nd/3.0/legalcode",
     code: "CC-BY-ND-3.0"},
    {label: "CC Attribution Share Alike 3.0 Unported",
     uri: "https://creativecommons.org/licenses/by-sa/3.0/legalcode",
     code: "CC-BY-SA-3.0"},
    {label: "CC Public Domain Mark 1.0",
     uri: "https://creativecommons.org/publicdomain/mark/1.0/",
     code: "PDM"}
  ].freeze

  RESOURCE_TYPES = {
    "image" => Cocina::Models::FileSetType.image,
    "page" => Cocina::Models::FileSetType.page,
    "file" => Cocina::Models::FileSetType.file,
    "audio" => Cocina::Models::FileSetType.audio,
    "video" => Cocina::Models::FileSetType.video,
    "document" => Cocina::Models::FileSetType.document,
    "3d" => Cocina::Models::FileSetType.three_dimensional,
    "object" => Cocina::Models::FileSetType.object
  }.freeze

  RELEASE_TARGETS = [
    %w[Searchworks Searchworks],
    %w[Earthworks Earthworks]
  ].freeze

  SYMPHONY = "symphony"
  PREVIOUS_CATKEY = "previous symphony"
end
