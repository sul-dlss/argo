import { Controller } from "stimulus"

export default class extends Controller {
    static targets = ["form"]

    open() {
      this.formTarget.hidden = false
    }

    close() {
      this.formTarget.hidden = true
    }
}
