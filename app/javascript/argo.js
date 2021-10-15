import ItemCollection from './modules/item_collection'
import './modules/permission_add'
import './modules/permission_grant'
import './modules/permission_list'
import './modules/sharing'
import TagsAutocomplete from './modules/tags_autocomplete'
import ProjectAutocomplete from './modules/project_autocomplete'

import Form from './modules/apo_form'
import bsCustomFileInput from 'bs-custom-file-input'
import {gridContext} from './registration/grid'
import {initializeReport} from './modules/report'

require('@github/time-elements')

function pathTo(path) {
  var root = $('body').attr('data-application-root') || '';
  return(root + path);
}

// Provide warnings when creating a collection.
function collectionExistsWarning(warningElem, field, value) {
    var client = new XMLHttpRequest();
    client.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            if (this.responseText == 'true') {
                warningElem.style.display = "block";
            } else {
                warningElem.style.display = "none";
            }
        }
    };
    client.open("GET", '/collections/exists?' + field + '=' + value, true);
    client.send();
}
$(document).on('keyup', '#collection_title', function(e) {
    collectionExistsWarning(document.getElementById('collection_title_warning'), 'title', e.target.value);
});

$(document).on('keyup', '#collection_catkey', function(e) {
    collectionExistsWarning(document.getElementById('collection_catkey_warning'), 'catkey', e.target.value);
});

export default class Argo {
    initialize() {
        this.tagsAutocomplete()
        this.projectAutocomplete()

        this.spreadsheet()
        this.buttonChecker()
        this.dateRangeQuery()
        this.itemCollection()
        this.populateDruids()

        this.apoEditor()
        this.collapsableSections()
        this.report()

        this.registration()
        this.blacklight()
        bsCustomFileInput.init() // Used for the agreement registration form
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

    spreadsheet() {
      $('#spreadsheet-upload-container').argoSpreadsheet()

      // When the user clicks the 'MODS bulk loads' button, a lightbox is opened.
      // The event 'loaded.blacklight.blacklight-modal' is fired just before this
      // Blacklight lightbox is shown.
      $('#blacklight-modal').on('loaded.blacklight.blacklight-modal', function(e){
          $('#spreadsheet-upload-container').argoSpreadsheet()
      })
    }

    buttonChecker() {
      $('a.disabled[data-check-url]').buttonChecker()
    }

    dateRangeQuery() {
      $('[data-range-query]').dateRangeQuery()
    }

    itemCollection() {
      new ItemCollection().initialize()
    }

    populateDruids() {
      $('[data-populate-druids]').populateDruids()
    }

    apoEditor() {
        var element = $("[data-behavior='apo-form']")
        if (element.length > 0) {
            new Form(element).init();
        }
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
