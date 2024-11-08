import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  // If the field is marked as invalid, then show the invalid (bootstrap) style.
  displayValidation (event) {
    const field = event.target
    field.closest('form').classList.add('was-validated')
  }
}
