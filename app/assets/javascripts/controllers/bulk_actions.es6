export default class extends Stimulus.Controller {
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
    const commonFields = this.element.querySelector('#common_fields')

    if (selectedTab == 'CreateVirtualObjectJob') {
      commonFields.classList.add('hidden')
    } else {
      commonFields.classList.remove('hidden')
    }
  }

  // Imports a CSV file and populates virtual object form fields
  importCsvFile(event) {
    const file = event.target.files[0]
    const reader = new FileReader()
    reader.readAsText(file)
    reader.onload = (event) => {
      let parentDruid, childDruids
      [parentDruid, childDruids] = this.parseCsv(event.target.result)
      const parentDruidField = this.element.querySelector('#bulk_action_create_virtual_object_parent_druid')
      parentDruidField.value = parentDruid
      const childDruidsField = this.element.querySelector('#bulk_action_create_virtual_object_child_druids')
      childDruidsField.value = childDruids
    }
  }

  // Parse comma-separated values and return values that can be inserted directly into form fields
  // NOTE: We are only importing the first line at this time.
  parseCsv(csvData) {
    const firstLine = csvData.split('\n').shift()
    // NOTE: `.filter(Boolean)` here removes blank strings which can be caused
    //       by CSV with multiple blank fields (which our expected source data
    //       contains)
    const druids = firstLine.split(',').filter(Boolean)
    return [druids[0], druids.slice(1).join("\n")]
  }
}
