import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [ "value", "ordinal", "startAt", "endAt" ]

  display(event) {
    event.preventDefault()

    // Save the old HTML so we can cancel.
    this.existingHTML = this.element.innerHTML

    // Display the editor
    let template = document.getElementById('edit-row')
    this.element.innerHTML = template.innerHTML

    // Populate the form with the values for this row
    this.valueTarget.value = this.data.get('value')
    this.ordinalTarget.value = this.data.get('ordinal')
    this.startAtTarget.value = this.data.get('start_at')
    this.endAtTarget.value = this.data.get('end_at')
  }

  save(event) {
    // remove the new form fields
    document.querySelector('[data-target="content-block-new.form"').remove()

    // Update the form so it updates the current item.
    let form = document.querySelector('[data-target="content-block-form"]')
    form.action = this.data.get('url')

    // Set the patch method on the form
    var input = document.createElement("input");
    input.type = 'hidden'
    input.name = '_method'
    input.value = 'patch'
    form.appendChild(input)
  }

  cancel(event) {
    event.preventDefault()
    this.element.innerHTML = this.existingHTML
  }
}
