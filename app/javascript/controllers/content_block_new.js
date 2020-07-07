import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [ "button", "form", "headerRow" ]

  display(event) {
    event.preventDefault()
    this.formTarget.classList.remove('d-none')
    // The header row doesn't display if there are no existing records, so display it now.
    this.headerRowTarget.classList.remove('d-none')
    this.buttonTarget.classList.add('d-none')
  }

  cancel(event) {
    event.preventDefault()
    this.hideForm()
  }

  hideForm() {
    this.formTarget.classList.add('d-none')
    this.buttonTarget.classList.remove('d-none')
  }
}
