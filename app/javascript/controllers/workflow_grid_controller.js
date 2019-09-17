import { Controller } from 'stimulus'

export default class extends Controller {
  connect() {
    this.load()

    if (this.data.has("refreshInterval")) {
      this.startRefreshing()
    }
  }

  startRefreshing() {
    setInterval(() => {
      this.load()
    }, this.data.get("refreshInterval"))
  }

  load() {
    // We're setting this header so that the controller can check for request.xhr?
    fetch(this.data.get("url"), { headers: { 'X-Requested-With': 'XMLHttpRequest' }})
      .then(response => response.text())
      .then(html => {
        this.element.innerHTML = html
      })
  }
}
