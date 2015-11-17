// This file contains JavaScript specific functionality for the bulk loading of spreadsheets.

console.log('loading ssheet file');

(function($) {
    /*
      jQuery plugin with utility functions for spreadsheet bulk upload submission
    */

    $.fn.argoSpreadsheet = function() {
	// var enableSubmit = function() {
	//     $('#spreadsheet_submit').prop('disabled', false);
	// };
	
	// var disableControl = function(ctrl) {
	//     ctrl.prop('disabled', true);
	// };
	
	// var enableControl = function(ctrl) {
	//     ctrl.prop('disabled', false);
	// };

	return this.each(function() {
	    console.log('start of call');
	    
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
	});
    };
})(jQuery);	
	



// The Blacklight onLoad event works better than the regular onLoad event if turbolinks is enabled.
Blacklight.onLoad(function(){

    console.log('blight onload');
    
    // When the user clicks the 'MODS bulk loads' button, a lightbox is opened. The event
    // 'loaded.blacklight.ajax-modal' is fired just before this Blacklight lightbox is shown.
    //$('#ajax-modal').on('loaded.blacklight.ajax-modal', function(e){
    $('#spreadsheet-upload-container').argoSpreadsheet();
    //});
});


// Confirmation modal dialog for when the user presses the delete button in the spreadsheet bulk upload table.
$(document).ready(function() {
    console.log('doc ready executing');

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
});
