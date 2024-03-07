import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['requiredFormField', 'requiredCsvField']
  static values = {
    csv: Boolean
  }

  connect () {
    // This check is used only at connect() time when the `csv` value has been
    // set in the HTML (which only occurs after the CSV form has been
    // submitted).
    //
    // Useful when there are  CSV upload errors.
    if (this.csvValue) this.toggleCsv()
  }

  toggleForm () {
    this.toggle(this.requiredFormFieldTargets, this.requiredCsvFieldTargets)
  }

  toggleCsv () {
    this.toggle(this.requiredCsvFieldTargets, this.requiredFormFieldTargets)
  }

  toggle (requiredInputs, optionalInputs) {
    requiredInputs.forEach((input) => input.setAttribute('required', true))
    optionalInputs.forEach((input) => input.removeAttribute('required'))
  }
}
