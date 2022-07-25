import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [ "selector", "druids" ]
  static values = {
    populateUrl: String
  }

  connect() {
    this.showTab()
  }

  // Shows the correct data tab based on the selected value of the dropdown
  showTab() {
    const url = this.selectorTarget.selectedOptions[0].value

    const turboFrame = this.element.querySelector('#bulk-action-form')
    turboFrame.src = url
  }

  populateDruids(e) {
    e.preventDefault()

    fetch(this.populateUrlValue, {
          headers: {
            'Accept': 'application/json'
          }
    })
    .then(resp => resp.json())
    .then((data) => {
      const docs = data.data.map(item => item.id).join("\n")
      this.druidsTarget.value = docs
    })
  }
}
