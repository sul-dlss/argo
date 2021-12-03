// Override Blacklights default error handler to give a more useful error message
// Ported upstream as https://github.com/projectblacklight/blacklight/pull/2386
Blacklight.modal.onFailure = function(jqXHR, textStatus, errorThrown) {
  console.error('Server error:', this.url, jqXHR.status, errorThrown)
  var contents =  `<div class="modal-header">
            <div class="h5 modal-title">There was a problem with your request.</div>
            <button type="button" class="blacklight-modal-close close" data-bs-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button></div>
            <div class="modal-body"><p>Expected a successful response from the server, but got an error</p>
            <pre>${this.type} ${this.url}` +
            `\n${jqXHR.status}: ${errorThrown}</pre><div>`
  $(Blacklight.modal.modalSelector).find('.modal-content').html(contents);
  $(Blacklight.modal.modalSelector).modal('show');
}
