import { Controller } from 'stimulus'

export default class extends Controller {
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
    const tabsWithUncommonFields = ['CreateVirtualObjectsJob', 'ImportTagsJob']
    const commonFields = this.element.querySelector('#common_fields')

    // Hide common fields for tab IDs present in tabsWithUncommonFields
    commonFields.hidden = tabsWithUncommonFields.includes(selectedTab)
  }
}
