import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
    static targets = ["form"]

    open() {
      this.formTarget.hidden = false
    }

    close() {
      this.formTarget.hidden = true
    }
}
