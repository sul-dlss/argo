import { Controller } from 'stimulus'

export default class extends Controller {
  open(event) {
    event.preventDefault()
    const href = this.element.getAttribute('href')
    $('#edit-modal').modal('show')
    const modal = document.querySelector('#edit-modal .modal-content')
    // Target is _top so that we can navigate to a new page when the form submission is successful
    modal.innerHTML = `<turbo-frame id="modal-frame" src="${href}" target="_top"></turbo-frame>`
  }
}
