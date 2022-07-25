import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
    static targets = [ "direction", "directionRow", "contentType"]

    connect() {
      this.render()
    }

    render() {
      switch (this.currentType()) {
        case 'https://cocina.sul.stanford.edu/models/image':
        case 'https://cocina.sul.stanford.edu/models/book':
          this.showDirection()
          break
        default:
          this.hideDirection()
      }
    }

    currentType() {
      return this.contentTypeTarget.selectedOptions[0].value
    }

    hideDirection() {
      this.directionRowTarget.hidden = true
      this.directionTarget.disabled = true
    }

    showDirection() {
      this.directionRowTarget.hidden = false
      this.directionTarget.disabled = false
    }
}
