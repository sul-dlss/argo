import TagsAutocomplete from './modules/tags_autocomplete'
import ProjectAutocomplete from './modules/project_autocomplete'

import {initializeReport} from './modules/report'

require('@github/time-elements')

export default class Argo {
    initialize() {
        this.tagsAutocomplete()
        this.projectAutocomplete()
        this.report()
    }

    report() {
      if (document.querySelector('[data-controller="report"]'))
        initializeReport()
    }

    tagsAutocomplete() {
      new TagsAutocomplete().initialize()
    }

    projectAutocomplete() {
      new ProjectAutocomplete().initialize()
    }
}
