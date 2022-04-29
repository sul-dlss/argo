import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['snippet', 'viewLessLink', 'viewMoreLink']

  static values = {
    expanded: { type: Boolean, default: true }
  }

  connect() {
    this.snippetLines = this.snippetTarget.innerText.split("\n")
    this.collapse()
  }

  expand() {
    if (!this.expandedValue && this.length > this.maxLength) {
      this.snippetTarget.innerText = this.snippetLines.join("\n")
      this.expandedValue = true
      this.viewMoreLinkTarget.hidden = true
      this.viewLessLinkTarget.hidden = false
    }
  }

  collapse() {
    if (this.expandedValue && this.length > this.maxLength) {
      this.snippetTarget.innerText = this.snippetLines.slice(0, this.maxLength).join("\n")
      this.expandedValue = false
      this.viewMoreLinkTarget.hidden = false
      this.viewLessLinkTarget.hidden = true
    }
  }

  get length() {
    return this.snippetLines.length
  }

  get maxLength() {
    return 10
  }
}
