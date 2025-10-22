import { Controller } from '@hotwired/stimulus'
import Choices from 'choices.js'

export default class extends Controller {
  connect () {
    if (!this.select) {
      this.select = new Choices(this.element, { removeItemButton: true, removeItemLabelText: (value) => `Remove item: ${value}` })
    }
  }
}
