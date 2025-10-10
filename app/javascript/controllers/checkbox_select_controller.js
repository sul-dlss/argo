import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['checkbox']

  checkAll (event) {
    event.preventDefault()
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = true
      // This is so object-reporter#toggleColumn gets called
      checkbox.dispatchEvent(new Event('change', { bubbles: true }))
    })
  }

  checkNone (event) {
    event.preventDefault()
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = false
      // This is so object-reporter#toggleColumn gets called
      checkbox.dispatchEvent(new Event('change', { bubbles: true }))
    })
  }
}
