(function($){
  $.fn.persistentModal = function() {

    return this.each(function(){
      var $modalLink = $(this);
      var linkTarget = $modalLink.attr('href');
      var linkText = $modalLink.text();
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
        $('div.persistent-modal').modal('hide');
        modalForTarget().modal('show');
      }

      function receiveAjax(data) {      
        //default to error text, replace if we got something back
        var contents = "Error retrieving content";
        if (data.readyState != 0) {
          contents = data;
        }

        // does it have a data- selector for container?  if so, just use the contents of that container
        // code modelled off of JQuery ajax.load. https://github.com/jquery/jquery/blob/master/src/ajax/load.js?source=c#L62
        var container =  $("<div>").
          append( contents ).find( Blacklight.ajaxModal.containerSelector ).first();
        if (container.size() !== 0) {
          contents = container.html();
        }

        $('body').append(persistentModalHtml(contents));
        modalForTarget().find('.modal-title').text(linkText);
        modalForTarget().find('[data-behavior="persistent-modal"]').persistentModal();
        applyModalCloseBehavior();
        showModal();
      }

      function createModal() {
        var jqxhr = $.ajax({
          url: linkTarget,
          dataType: 'text'
        });

        jqxhr.always( receiveAjax );
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

      function persistentModalHtml(modalBody) {
        modalHtml = [
          // the 'data-backdrop="static"' and 'data-keyboard="false"' attributes keep the modal from closing on clickaway or escape, respectively
          '<div class="modal persistent-modal" tabindex="-1" role="modal" data-persistent-modal-url="' + linkTarget + '" data-backdrop="static" data-keyboard="false">',
          '  <div class="modal-dialog">',
          '    <div class="modal-header">',
          '      <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>',
          '      <h3 class="modal-title">TITLE</h3>',
          '    </div>',
          '    <div class="modal-content">',
          '      <div class="modal-body">',
          '        '+modalBody,
          '      </div>',
          '      <div class="form-group cancel-footer">',
          '        <button data-behavior="cancel-link" class="cancel-link btn btn-link">Cancel</button>',
          '      </div>',
          '    </div>',
          '  </div>',
          '</div>'
        ].join('\n');
        return modalHtml;
      }
    });
  };

})(jQuery);

Blacklight.onLoad(function() {
  $('[data-behavior="persistent-modal"]').persistentModal();
});