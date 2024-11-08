import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['add_item', 'template']
  static values = { selector: String }

  initialize () {
    this.count = 1
  }

  addAssociation (event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/TEMPLATE_RECORD/g, crypto.randomUUID())
    this.add_itemTarget.insertAdjacentHTML('beforebegin', content)
    this.resetValidations()
    this.count++
  }

  // Prevent the new fields from showing up marked as invalid
  resetValidations () {
    this.add_itemTarget.closest('form').classList.remove('was-validated')
  }

  removeAssociation (event) {
    event.preventDefault()
    event.target.closest(this.selectorValue).remove()
    this.count--
  }

  populateFromPastedData (event) {
    const paste = (event.clipboardData || window.clipboardData).getData('text')
    const lines = paste.split(/\r?\n/)

    // Add extra lines as needed
    while (this.count < lines.length) {
      this.addAssociation(new Event('dummy'))
    }

    const rowsOnPage = this.element.querySelectorAll(this.selectorValue)

    lines.forEach((line, index) => {
      const [barcode, catalogRecordId, sourceId, label] = line.split(/\t/)

      const elements = rowsOnPage[index].querySelectorAll('input')
      elements[0].value = barcode
      elements[1].value = catalogRecordId
      elements[2].value = sourceId
      elements[3].value = label
      // Trigger client side validations for existing rows
      // Newly added rows will validate when the connect for RegistrationItemRowController is run at
      // the conclusion of this method.
      elements.forEach(element => element.dispatchEvent(new Event('change')))
    })

    event.preventDefault()
  }
}
