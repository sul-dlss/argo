import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [ "commonFields", "pids" ]
  static values = {
    populateUrl: String
  }

  // Shows the correct data tab based on the selected value of the dropdown
  showTab(event) {
    const selected = event.target.selectedOptions[0].value

    const oldTab = this.element.querySelector('.tab-content > .active')
    oldTab.classList.remove('active')

    const newTab = this.element.querySelector(`.tab-content > #${selected}`)
    newTab.classList.add('active')

    this.toggleCommonFieldVisibility(selected)
  }

  // Toggles visibility of common fields based on selected tab
  toggleCommonFieldVisibility(selectedTab) {
    const tabsWithUncommonFields = ['CreateVirtualObjectsJob', 'ImportTagsJob', 'RegisterDruidsJob', 'SetCatkeysAndBarcodesCsvJob', 'SetSourceIdsCsvJob', 'ManageEmbargoesJob']

    // Hide common fields for tab IDs present in tabsWithUncommonFields
    this.commonFieldsTarget.hidden = tabsWithUncommonFields.includes(selectedTab)
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
      this.pidsTarget.value = docs
    })
  }
}
