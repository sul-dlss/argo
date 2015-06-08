// This file contains JavaScript specific functionality for the bulk loading of spreadsheets.


// The Blacklight onLoad event works better than the regular onLoad event if turbolinks is enabled.
Blacklight.onLoad(function(){

    // When the user clicks the "MODS bulk loads" button, a lightbox is opened. The event
    // "loaded.blacklight.ajax-modal" is fired just before this Blacklight lightbox is shown.
    $("#ajax-modal").on("loaded.blacklight.ajax-modal", function(e){

	// None of the form controls should be functional until a file has been selected
	$("#filetypes_1").prop("disabled", true);
	$("#filetypes_2").prop("disabled", true);
	$("#convert_only").prop("disabled", true);
	$("#spreadsheet_submit").prop("disabled", true);
	$("#note_text").prop("disabled", true);

	$("#spreadsheet_file").change(function (){
	    $("#filetypes_1").prop("disabled", false);
	    $("#filetypes_2").prop("disabled", false);
	    $("#note_text").prop("disabled", false);
	    $("#convert_only").prop("disabled", true);
	});
	
	$("#filetypes_2").click(function() {
            $("#convert_only").prop("disabled", false);
	    $("#spreadsheet_submit").prop("disabled", false);
	});
	
	$("#filetypes_1").click(function() {
	    $("#convert_only").prop("checked", false);
	    $("#convert_only").prop("disabled", true);
	    $("#spreadsheet_submit").prop("disabled", false);
	});
    });
});

