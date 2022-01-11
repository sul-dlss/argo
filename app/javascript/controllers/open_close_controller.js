import { Controller } from "stimulus"

export default class extends Controller {
    static values = { url: String }

    connect() {
      fetch(this.urlValue)
        .then(response => response.text())
        .then(value => {
           this.element.hidden = value == 'false'
        })
    }
}
