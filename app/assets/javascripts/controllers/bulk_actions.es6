export default class extends Stimulus.Controller {
  // Shows the correct data tab based on the selected value of the dropdown
  showTab(event) {
    const selected = event.target.selectedOptions[0].value

    const oldTab = this.element.querySelector('.tab-content > .active')
    oldTab.classList.remove('active')

    const newTab = this.element.querySelector(`.tab-content > #${selected}`)
    newTab.classList.add('active')
  }
}
