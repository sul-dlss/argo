// This file contains JavaScript specific functionality for the bulk loading of spreadsheets.

function enable_submit()
{
    $("#spreadsheet_submit").prop("disabled", false);
}

function disable_control(ctrl)
{
    ctrl.prop("disabled", true)
}

function enable_control(ctrl)
{
    ctrl.prop("disabled", false)
}


// The Blacklight onLoad event works better than the regular onLoad event if turbolinks is enabled.
Blacklight.onLoad(function(){

    // When the user clicks the "MODS bulk loads" button, a lightbox is opened. The event
    // "loaded.blacklight.ajax-modal" is fired just before this Blacklight lightbox is shown.
    $("#ajax-modal").on("loaded.blacklight.ajax-modal", function(e){
	var input_controls = [$("#filetypes_1"), $("#filetypes_2"), $("#convert_only"), $("#note_text")]
	var radio_buttons = input_controls.slice(0, 3)
	
	// Adjust the width of the lightbox when it hosts a metadata spreadsheet upload form.
	$("#spreadsheet-upload-container").parent().parent().css("width", "650px");

	// Width of the lightbox when hosting a metadata bulk upload log
	$("#spreadsheet-log-container").parent().parent().css("width", "700")
	
	// None of the form controls should be functional until a file has been selected
	$("#spreadsheet_submit").prop("disabled", true);
	input_controls.map(disable_control)

	// Enable everything except for the submit button upon file upload
	$("#spreadsheet_file").change(function (){
	    input_controls.map(enable_control)
	});

	// Only when the user has uploaded a file AND selected one of the radio buttons should it be possible to submit
	radio_buttons.forEach(function(button) {
	    button.click(function() {
		enable_submit()
	    });
	});
    });
});

