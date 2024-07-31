import { Controller } from '@hotwired/stimulus'

// Validates free-text tags fields and sets the .invalid class on elements
// that aren't well formed tags
export default class extends Controller {
  connect () {
    this.validate()
  }

  validate () {
    const parts = this.element.value.trim().split(/\s*:\s*/)
    this.element.value = parts.join(' : ')
    this.element.classList.toggle('is-invalid', this.is_invalid(parts))
  }

  is_invalid (parts) {
    return (parts.length === 1 && parts[0] !== '') ||
             (parts.length > 1 && parts.includes(''))
  }
}
