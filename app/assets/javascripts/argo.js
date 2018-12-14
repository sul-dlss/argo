// Put your application scripts here

$.fn.preload = function() {
    this.each(function(){
        $('<img/>')[0].src = this;
    });
}

function pathTo(path) {
  var root = $('body').attr('data-application-root') || '';
  return(root + path);
}

Argo = {
    initialize: function() {
      this.apoEditor()
    },
    apoEditor: function () {
        var element = $("[data-behavior='apo-form']")
        if (element.length > 0) {
            var Form = require('modules/apo_form');
            new Form(element).init();
        }
    }
}

$(document).ready(function() {
    $('#logo h1').remove();
    $('.start-open').addClass('twiddle-open');
    $('.start-open').next('ul').show();
    $('.collapsible-section').click(function(e) {
        // Do not want a click on the "MODS bulk loads" button to cause collapse
        if(!(e.target.id === 'bulk-button')) {
            $(this).next('div').slideToggle();
            $(this).toggleClass('collapsed');
        }
    });

    $('#facets a.remove').map(function() { $(this).html('') })
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
