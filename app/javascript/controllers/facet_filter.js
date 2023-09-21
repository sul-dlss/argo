import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['list']

  filter (event) {
    const filter = event.target.value.toUpperCase()
    const li = this.listTarget.getElementsByTagName('li')

    // Loop through all list items, and hide those who don't match the search query
    for (let i = 0; i < li.length; i++) {
      const a = li[i].getElementsByTagName('a')[0]
      const txtValue = a.textContent || a.innerText
      if (txtValue.toUpperCase().indexOf(filter) > -1) {
        li[i].style.display = ''
      } else {
        li[i].style.display = 'none'
      }
    }
  }
}
