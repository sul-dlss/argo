import Form from 'modules/apo_form'

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
        this.apoEditor()
        this.collapsableSections()
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
