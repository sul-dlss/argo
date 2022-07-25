import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
    // TODO: This same code is in button.js Perhaps it can be extracted?
    open(event) {
      event.preventDefault()
      const href = this.element.getAttribute('href')
      const element = document.getElementById('edit-modal')
      const instance = bootstrap.Modal.getOrCreateInstance(element)
      instance.show()
      const modal = document.querySelector('#edit-modal .modal-content')
      // Target is _top so that we can navigate to a new page when the form submission is successful
      modal.innerHTML = `<turbo-frame id="modal-frame" src="${href}" target="_top"></turbo-frame>`
    }
}
