'use strict';

(function ($) {
    // jQuery plugin with utility functions for spreadsheet bulk upload
    // submission

    $.fn.argoSpreadsheet = function () {
        var $el;             // Use dollar sign for JQuery objects
        var $submitButton;
	
	var enableSubmit = function() {
	    $submitButton.prop('disabled', false);
	};
	
	var disableControl = function(ctrl) {
	    ctrl.prop('disabled', true);
	};
	
	var enableControl = function(ctrl) {
	    ctrl.prop('disabled', false);
	};

	return this.each(function() {
	    $el = $(this);     // $el is now spreadsheet-upload-container
	    $submitButton = $el.find('#spreadsheet_submit');
	    
	    // When the user clicks the 'MODS bulk loads' button, a lightbox is
	    // opened. The event 'loaded.blacklight.ajax-modal' is fired just
	    // before this Blacklight lightbox is shown.
	    var inputControls = [$('#filetypes_1'),
				 $('#filetypes_2'),
				 $('#convert_only'),
				 $('#note_text')];
	    var radioButtons = inputControls.slice(0, 3);
	    
	    // Adjust the width of the lightbox when it hosts a metadata
	    // spreadsheet upload form.
	    $el.parent().parent().css('width', '650px');
	    
	    // Width of the lightbox when hosting a metadata bulk upload log
	    $el.parent().parent().css('width', '700');
	    
	    // None of the form controls should be functional until a file has been
	    // selected
	    $submitButton.prop('disabled', true);
	    inputControls.map(disableControl);
	    
	    // Enable everything except for the submit button upon file upload
	    $el.find('#spreadsheet_file').change(function (){
		inputControls.map(enableControl);
	    });
	    
	    // Only when the user has uploaded a file AND selected one of the
	    // radio buttons should it be possible to submit
	    radioButtons.forEach(function(button) {
		button.click(function() {
		    enableSubmit();
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
    
    // When the user clicks the 'MODS bulk loads' button, a lightbox is opened.
    // The event 'loaded.blacklight.ajax-modal' is fired just before this
    // Blacklight lightbox is shown.
    $('#ajax-modal').on('loaded.blacklight.ajax-modal', function(e){
	$('#spreadsheet-upload-container').argoSpreadsheet();
    });
});


// Confirmation modal dialog for when the user presses the delete button in the
// spreadsheet bulk upload table.
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
