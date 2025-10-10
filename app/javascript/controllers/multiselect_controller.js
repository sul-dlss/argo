import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    this.select = new TomSelect(this.element)
  }
  disconnect() {
    this.select.destroy()
  }
}