import ItemCollection from './modules/item_collection'
import TagsAutocomplete from './modules/tags_autocomplete'
import ProjectAutocomplete from './modules/project_autocomplete'

import {gridContext} from './registration/grid'
import {initializeReport} from './modules/report'

require('@github/time-elements')

export default class Argo {
    initialize() {
        this.tagsAutocomplete()
        this.projectAutocomplete()

        this.itemCollection()

        this.collapsableSections()
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

    itemCollection() {
      new ItemCollection().initialize()
    }

    // Collapse sections on the item show pages when the cheverons are clicked
    collapsableSections() {
      $('.collapsible-section').click(function(e) {
          // Do not want a click on the "MODS bulk loads" button on the APO show page to cause collapse
          if(e.target.id !== 'bulk-button') {
              $(this).next('div').slideToggle()
              $(this).toggleClass('collapsed')
          }
      })
    }
}
