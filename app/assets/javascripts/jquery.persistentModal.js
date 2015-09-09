(function($){
  $.fn.persistentModal = function() {

    return this.each(function(){
      var $modalLink = $(this);
      var linkTarget = $modalLink.attr('href');
      // var linkTargetWithModalParam = linkTarget + '&modal=true';
      var linkTargetWithModalParam = linkTarget;
      init();

      function init(){
        $modalLink.on('click', function(e){
          e.preventDefault();
          toggleOrCreateModal();
        });
      }

      function toggleOrCreateModal() {
        if (!modalIsPresent()) {
          createModal();
        }
        showModal();
      }

      function showModal() {
        modalForTarget().modal('show');
      }

      // function createModal() {
      //   $('body').append(persistentModalTemplate());
      //   applyModalCloseBehavior();
      // }

      // function onFailure(data) {
      //   var contents =  "<div class='modal-header'>" +
      //            "<button type='button' class='close' data-dismiss='modal' aria-hidden='true'>×</button>" +
      //            "Network Error</div>";
      //   $(Blacklight.ajaxModal.modalSelector).find('.modal-content').html(contents);
      //   $(Blacklight.ajaxModal.modalSelector).modal('show'); 
      // }

      function receiveAjax(data) {      
        if (data.readyState == 0) {
          // Network error, could not contact server. 
          // Blacklight.ajaxModal.onFailure(data)
        } else {

          // important we don't execute script tags, we shouldn't. 
          // var contents = jQuery.parseHTML(data.responseText);
          var contents = data.responseText;
        
          // does it have a data- selector for container?
          // code modelled off of JQuery ajax.load. https://github.com/jquery/jquery/blob/master/src/ajax/load.js?source=c#L62
          var container =  $("<div>").
            append( contents ).find( Blacklight.ajaxModal.containerSelector ).first();
          if (container.size() !== 0) {
            contents = container.html();
          }
// debugger;
          // tmplt = $(persistentModalTemplate())
          // tmplt.find('.modal-content').html(contents);
          // $('body').append(tmplt.html());

          $('body').append(persistentModalHtml(contents));
          showModal();

          // $('[data-persistent-modal-url="'+linkTarget+'"] div.modal-dialog div.modal-content div.modal-body').html(contents)

          // $(Blacklight.ajaxModal.modalSelector).find('.modal-content').html(contents);

          // // send custom event with the modal dialog div as the target
          // // var e    = $.Event('loaded.blacklight.ajax-modal')
          // $(Blacklight.ajaxModal.modalSelector).trigger(e);
          // // if they did preventDefault, don't show the dialog
          // if (e.isDefaultPrevented()) return;

          // $(Blacklight.ajaxModal.modalSelector).modal('show');      
        }
      }

      function createModal() {
        var jqxhr = $.ajax({
          url: linkTargetWithModalParam
        });

        jqxhr.always( receiveAjax );

        // $('body').append(persistentModalHtml("test contents outside callback"));

        applyModalCloseBehavior();
      }

      function applyModalCloseBehavior() {
        modalForTarget().find('[data-behavior="cancel-link"]').on('click', function() {
          modalForTarget().modal('hide');
          modalForTarget().remove();
        });
      }

      function modalForTarget() {
        return $('[data-persistent-modal-url="' + linkTarget + '"]');
      }

      function modalIsPresent() {
        return modalForTarget().length > 0;
      }

      function persistentModalTemplate() {
        return [
          '<div class="modal persistent-modal" tabindex="-1" role="modal" data-persistent-modal-url="' + linkTarget + '">',
            '<div class="modal-dialog">',
              '<div class="modal-content">',
                '<div class="modal-body">',
                  // '<iframe width="100%" height="90%" frameborder="0" src="' + linkTargetWithModalParam + '" />',
                '</div>',
                '<div class="form-group cancel-footer">',
                  '<button data-behavior="cancel-link" class="cancel-link btn btn-link">Cancel</button>',
                '</div>',
              '</div>',
            '</div>',
          '</div>'
        ].join('\n');
      }

      function persistentModalHtml(modalBody) {
        return [
          '<div class="modal persistent-modal" tabindex="-1" role="modal" data-persistent-modal-url="' + linkTarget + '">',
            '<div class="modal-dialog">',
              '<div class="modal-content">',
                '<div class="modal-body">',
                  modalBody,
                '</div>',
                '<div class="form-group cancel-footer">',
                  '<button data-behavior="cancel-link" class="cancel-link btn btn-link">Cancel</button>',
                '</div>',
              '</div>',
            '</div>',
          '</div>'
        ].join('\n');
      }
    });
  };

})(jQuery);

Blacklight.onLoad(function() {
  $('[data-behavior="persistent-modal"]').persistentModal();
});