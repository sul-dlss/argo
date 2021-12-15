import TagsAutocomplete from './modules/tags_autocomplete'
import ProjectAutocomplete from './modules/project_autocomplete'

import {gridContext} from './registration/grid'
import {initializeReport} from './modules/report'

require('@github/time-elements')

export default class Argo {
    initialize() {
        this.tagsAutocomplete()
        this.projectAutocomplete()
        this.report()
        this.registration()
        this.blacklight()
    }

    // Because blacklight doesn't yet support turbo, we need to manually initialize
    // the features we care about.
    blacklight() {
      Blacklight.activate()
    }

    report() {
      if (document.querySelector('[data-controller="report"]'))
        initializeReport()
    }

    registration() {
      if (document.querySelector('[data-controller="grid"]'))
        gridContext().initialize()
    }

    tagsAutocomplete() {
      new TagsAutocomplete().initialize()
    }

    projectAutocomplete() {
      new ProjectAutocomplete().initialize()
    }
}
