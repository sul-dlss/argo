// This file contains JavaScript specific functionality for the bulk loading of spreadsheets.

// An object to prevent us from polluting the global namespace with all these generically named functions.
var argoSpreadsheet = {
    enableSubmit : function()
    {
	$('#spreadsheet_submit').prop('disabled', false);
    },
    
    disableControl : function(ctrl)
    {
	ctrl.prop('disabled', true);
    },
    
    enableControl : function(ctrl)
    {
	ctrl.prop('disabled', false);
    },

    loadUploadForm : function()
    {
	// When the user clicks the 'MODS bulk loads' button, a lightbox is opened. The event
	// 'loaded.blacklight.ajax-modal' is fired just before this Blacklight lightbox is shown.
	var inputControls = [$('#filetypes_1'), $('#filetypes_2'), $('#convert_only'), $('#note_text')];
	var radioButtons = inputControls.slice(0, 3);
	
	// Adjust the width of the lightbox when it hosts a metadata spreadsheet upload form.
	$('#spreadsheet-upload-container').parent().parent().css('width', '650px');
	
	// Width of the lightbox when hosting a metadata bulk upload log
	$('#spreadsheet-log-container').parent().parent().css('width', '700');
	
	// None of the form controls should be functional until a file has been selected
	$('#spreadsheet_submit').prop('disabled', true);
	inputControls.map(argoSpreadsheet.disableControl);
	
	// Enable everything except for the submit button upon file upload
	$('#spreadsheet_file').change(function (){
	    inputControls.map(argoSpreadsheet.enableControl);
	});
	
	// Only when the user has uploaded a file AND selected one of the radio buttons should it be possible to submit
	radioButtons.forEach(function(button) {
	    button.click(function() {
		argoSpreadsheet.enableSubmit();
	    });
	});
    },
};


// The Blacklight onLoad event works better than the regular onLoad event if turbolinks is enabled.
Blacklight.onLoad(function(){
    'use strict';

    // When the user clicks the 'MODS bulk loads' button, a lightbox is opened. The event
    // 'loaded.blacklight.ajax-modal' is fired just before this Blacklight lightbox is shown.
    $('#ajax-modal').on('loaded.blacklight.ajax-modal', function(e){
	argoSpreadsheet.loadUploadForm();
    });
});


// Confirmation modal dialog for when the user presses the delete button in the spreadsheet bulk upload table.
$(document).ready(function() {
    'use strict';

    // The form we want to submit has both ':' and '/' in its ID, which need to be escaped
    function escapeCharacters(identifier) {
	return '#' + identifier.replace( /(:|\.|\[|\]|,|\/)/g, '\\$1' );
    }

    
    $('.job-delete-button').click(function() {
	var formParentId = $(this).parent().attr('id');
	
	$('#confirm-delete-job').click(function(){
	    
	    // Submit the form when the Delete button in the modal is clicked
	    $(escapeCharacters(formParentId)).submit();
	});
    });

    // The bulk upload form can also be reached directly without opening a modal
    if($('#spreadsheet-upload-container').length) {
	argoSpreadsheet.loadUploadForm();
    }
});
