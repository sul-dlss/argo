import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["add_item", "template"]
  static values = { selector: String }

  addAssociation(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/TEMPLATE_RECORD/g, new Date().valueOf())
    this.add_itemTarget.insertAdjacentHTML('beforebegin', content)
  }

  removeAssociation(event) {
    event.preventDefault()
    event.target.closest(this.selectorValue).remove()
  }
}
