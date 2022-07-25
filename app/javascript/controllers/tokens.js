import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [ "output", "result", "button" ]

  fetchToken(event) {
    fetch(this.data.get("url"), {
      method: 'POST',
      headers: {
        "X-CSRF-Token": Blacklight.csrfToken(),
      }
    }).then(response => response.text())
      .then(token => {
        this.buttonTarget.style.display = "none"
        this.resultTarget.style.display = "inline"
        this.outputTarget.value = token
        this.outputTarget.select()
      })
  }
}
