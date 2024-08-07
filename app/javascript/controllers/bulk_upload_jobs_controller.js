import bootstrap from 'bootstrap/dist/js/bootstrap'
import { Controller } from '@hotwired/stimulus'

// This should be controlling a <form> node
export default class extends Controller {
  openModal (event) {
    event.preventDefault()

    const modalElement = document.getElementById('confirm-delete-modal')
    bootstrap.Modal.getOrCreateInstance(modalElement).show()

    const formParent = this.element
    // Replace the button every time the modal is open ensures there are no stale listeners.
    modalElement.querySelector('.modal-footer').innerHTML = `
          <button type="button" class="btn btn-primary" id="bulk-delete-confirm">Delete</button>
          <button type="button" class="btn btn-outline-primary" data-bs-dismiss="modal">Cancel</button>
        `
    modalElement
      .querySelector('#bulk-delete-confirm')
      .addEventListener('click', () => formParent.submit())
  }
}
