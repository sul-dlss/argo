import Form from 'modules/apo_form'
import CollectionEditor from 'controllers/collection_editor'
import BulkActions from 'controllers/bulk_actions'
import BulkUpload from 'controllers/bulk_upload'
import Tokens from 'controllers/tokens'
import WorkflowGrid from 'controllers/workflow_grid_controller'
import { Application } from 'stimulus'
require('@github/time-elements')

function pathTo(path) {
  var root = $('body').attr('data-application-root') || '';
  return(root + path);
}


// Allows filtering a list of facets.
function filterList() {
    var input = document.getElementById('filterInput');
    var filter = input.value.toUpperCase();
    var ul = document.getElementsByClassName('facet-values')[0];
    var li = ul.getElementsByTagName('li');

    // Loop through all list items, and hide those who don't match the search query
    for (var i = 0; i < li.length; i++) {
        var a = li[i].getElementsByTagName("a")[0];
        var txtValue = a.textContent || a.innerText;
        if (txtValue.toUpperCase().indexOf(filter) > -1) {
            li[i].style.display = "";
        } else {
            li[i].style.display = "none";
        }
    }
}

$(document).on('keyup', '#filterInput', function(e) { filterList() });

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
        this.apoEditor()
        this.collapsableSections()
        const application = Application.start()
        application.register("bulk_actions", BulkActions)
        application.register("bulk_upload", BulkUpload)
        application.register("workflow-grid", WorkflowGrid)
        application.register("collection-editor", CollectionEditor)
        application.register("tokens", Tokens)
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
