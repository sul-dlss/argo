import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "requiredFormField", "requiredCsvField" ]

  toggleForm(event) {
    this.toggle(this.requiredFormFieldTargets, this.requiredCsvFieldTargets)
  }

  toggleCsv() {
    this.toggle(this.requiredCsvFieldTargets, this.requiredFormFieldTargets)
  }

  toggle(requiredInputs, optionalInputs) {
    requiredInputs.forEach((input) => input.required = true)
    optionalInputs.forEach((input) => input.required = false)
  }
}
