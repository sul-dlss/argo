import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['textExtractionLanguages', 'textExtractionDropdown',
    'selectedLanguages', 'languageWarning', 'dropdownContent']

  static values = { languages: Array }

  connect () {
    // Clear the form if the page is refreshed.
    // When the form has been filled out
    // and the page is refreshed, without this line the form stays filled out.
    this.element.querySelector('form').reset()
  }

  languageDropdown (event) {
    const ishidden = this.dropdownContentTarget.classList.contains('d-none')
    this.dropdownContentTarget.classList.toggle('d-none')
    this.textExtractionDropdownTarget.querySelector('#caret').innerHTML = `<i class="bi bi-caret-${ishidden ? 'up' : 'down'}">`
    event.preventDefault()
  }

  clickOutside (event) {
    const isshown = !this.dropdownContentTarget.classList.contains('d-none')
    const inselectedlangs = event.target.classList.contains('pill-close')
    const incontainer = this.element.querySelector('form').contains(event.target)

    if (!incontainer && !inselectedlangs && isshown) {
      this.languageDropdown(event)
    }
  }

  languageUpdate (event) {
    const target = event.target ? event.target : event
    if (target.checked) {
      this.languagesValue = this.languagesValue.concat([target.dataset])
    } else {
      this.languagesValue = this.languagesValue.filter(lang => lang.textExtractionValue !== target.value)
    }
  }

  languagesValueChanged () {
    if (this.languagesValue.length === 0) {
      this.selectedLanguagesTarget.classList.add('d-none')
    } else {
      this.selectedLanguagesTarget.classList.remove('d-none')
      this.selectedLanguagesTarget.innerHTML = `<div>Selected language(s)</div>
                                                <ul class="list-unstyled border rounded mb-3 p-1">${this.renderLanguagePills()}</ul>`
    }

    if (this.languagesValue.length > 8) {
      this.languageWarningTarget.classList.remove('d-none')
    } else {
      this.languageWarningTarget.classList.add('d-none')
    }
  }

  search (event) {
    const searchterm = event.target.value.replace(/[^\w\s]/gi, '').toLowerCase()
    this.dropdownContentTarget.classList.remove('d-none')
    this.textExtractionLanguagesTargets.forEach(target => {
      const compareterm = target.dataset.textExtractionLabel.replace(/[^\w\s]/gi, '').toLowerCase()
      if (compareterm.includes(searchterm)) {
        target.parentElement.classList.remove('d-none')
      } else {
        target.parentElement.classList.add('d-none')
      }
    })
  }

  deselect (event) {
    event.preventDefault()

    const target = this.textExtractionLanguagesTargets.find((language) => language.dataset.textExtractionValue === event.target.id)
    if (target) target.checked = false
    this.languageUpdate(target)
  }

  renderLanguagePills () {
    return this.languagesValue.map((language) => {
      return `
        <li class="d-inline-flex gap-2 align-items-center my-2">
          <span class="bg-light rounded-pill border language-pill">
            <span class="language-label">
              ${language.textExtractionLabel}
            </span>
            <button data-action="${this.identifier}#deselect" id="${language.textExtractionValue}" type="button" class="btn-close py-0 pill-close" aria-label="Remove ${language.textExtractionLabel}"></button>
          </span>
        </li>
      `
    }).join('')
  }
}
