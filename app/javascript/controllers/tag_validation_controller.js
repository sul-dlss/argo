import { Controller } from '@hotwired/stimulus'

// Alerts the form to display errors if the tags aren't well formed
export default class extends Controller {
  connect () {
    this.validate()
  }

  validate () {
    if (this.element.validity.patternMismatch) {
      this.element.reportValidity()
    }
  }
}
