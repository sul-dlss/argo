$(document).ready(function() {

  function collectionErrorOccurred(msg = 'An error occurred adding or removing the collection.') {
    window.alert(msg);
  }

  $('#remove_collection').click(function() {
    $.ajax({
            url: ($(this).parent()).attr('href'),
            dataType: 'json',
            type: 'get',
            error: function() { collectionErrorOccurred(); },
            success: function(data, status, xhr) {
              //if app isn't running at all, xhr annoyingly
              //reports success with status 0.
              if (xhr.status !== 0) {
                $('#collection_message').html(xhr.responseJSON.message);
                $('#collection_' + xhr.responseJSON.druid).remove();
              } else {
                collectionErrorOccurred(xhr.responseJSON.message);
              }
            }
          });
    return false;
  }); // end remove_collection.click

  $('#add_collection').click(function() {
    var form = $('#add_collection_form');
    $.ajax({
            url: form.attr('action'),
            dataType: 'json',
            type: form.attr('method').toUpperCase(),
            data: form.serialize(),
            error: function() { collectionErrorOccurred(); },
            success: function(data, status, xhr) {
              //if app isn't running at all, xhr annoyingly
              //reports success with status 0.
              if (xhr.status !== 0) {
                $('#collection_message').html(xhr.responseJSON.message);
                $('#collection_list').append(xhr.responseJSON.new_collection_html);
              } else {
                collectionErrorOccurred(xhr.responseJSON.message);
              }
            }
          });
    return false;
  }); // end remove_collection.click
});
