import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [ "output", "result", "button" ]

  fetchToken(event) {
    const csrfToken = Rails.csrfToken()
    fetch(this.data.get("url"), {
      method: 'POST',
      headers: {
        "X-CSRF-Token": csrfToken,
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
