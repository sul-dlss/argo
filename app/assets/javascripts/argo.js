function pathTo(path) {
  var root = $('body').attr('data-application-root') || '';
  return(root + path);
}

Argo = {
    initialize: function() {
      this.apoEditor()

      const application = Stimulus.Application.start()
      const BulkActions = require('controllers/bulk_actions')
      application.register("bulk_actions", BulkActions)
    },
    apoEditor: function () {
        const element = $("[data-behavior='apo-form']")
        if (element.length > 0) {
            const Form = require('modules/apo_form');
            new Form(element).init();
        }
    }
}

$(document).ready(function() {
    $('.collapsible-section').click(function(e) {
        // Do not want a click on the "MODS bulk loads" button to cause collapse
        if(!(e.target.id === 'bulk-button')) {
            $(this).next('div').slideToggle();
            $(this).toggleClass('collapsed');
        }
    });
});


Blacklight.onLoad(function() { Argo.initialize() });


// When a user selects a spreadsheet file for uploading via the bulk metadata upload function,
// this function is called to verify the filename extension.
function validate_spreadsheet_filetype()
{
    var filename = $('#spreadsheet_file').val().toLowerCase();
    $('span#bulk-spreadsheet-warning').text("");

    // Use lastIndexOf() since endsWith() is part of the latest ECMAScript 6 standard and not implemented
    // in Poltergeist/PhantomJS yet.
    if((filename.lastIndexOf(".xlsx") == -1) && (filename.lastIndexOf(".xls") == -1) &&  (filename.lastIndexOf(".xml") == -1) && (filename.lastIndexOf(".csv") == -1))
        $('span#bulk-spreadsheet-warning').text("Note: Only spreadsheets or XML files are allowed. Please check your selected file.");
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
