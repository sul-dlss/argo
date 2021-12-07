'use strict';

// Confirmation modal dialog for when the user presses the delete button in the
// spreadsheet bulk upload table.
document.addEventListener("turbo:load", function() {
  // The form we want to submit has both ':' and '/' in its ID, which need to
  // be escaped
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
