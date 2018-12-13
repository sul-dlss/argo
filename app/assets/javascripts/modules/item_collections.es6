'use strict';

function collectionErrorOccurred(msg = 'An error occurred adding or removing the collection.') {
  window.alert(msg);
}

Blacklight.onLoad(function() {

  // bind with .on('click') since the DOM does not have these elements until the modal pops up
  $(document).on('click', '#remove_collection', function(evt) {
    $.ajax({
            url: ($(this).parent()).attr('href'),
            dataType: 'json',
            type: 'get',
            error: function() { collectionErrorOccurred(); },
            success: function(data, status, xhr) {
              $('#collection_message').html(xhr.responseJSON.message);
              $('#collection_' + xhr.responseJSON.druid).remove();
            }
          });
    evt.preventDefault();
  }); // end remove_collection.click

  $(document).on('click', '#add_collection', function(evt) {
    var form = $('#add_collection_form');
    $.ajax({
            url: form.attr('action'),
            dataType: 'json',
            type: form.attr('method').toUpperCase(),
            data: form.serialize(),
            error: function() { collectionErrorOccurred(); },
            success: function(data, status, xhr) {
              $('#collection_message').html(xhr.responseJSON.message);
              $('#collection_list').append(xhr.responseJSON.new_collection_html);
            }
          });
      evt.preventDefault();
  }); // end add_collection.click

});
