import bootstrap from 'bootstrap/dist/js/bootstrap'
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  copy (event) {
    let formattedOutput = ''

    // iterate over all facet values and construct a tab delimited string with two columns
    const facetList = document.querySelectorAll('.modal-body .facet-values li')
    facetList.forEach(function (facetItem) {
      const facetValue = facetItem.querySelector('.facet-label a').innerHTML
      const facetCount = facetItem.querySelector('.facet-count').innerHTML
      formattedOutput += facetValue + '\t' + facetCount + '\n'
    })

    navigator.clipboard.writeText(formattedOutput)
    event.preventDefault()

    const popover = new bootstrap.Popover(event.target, {
      content: 'Copied.',
      placement: 'top',
      trigger: 'manual',
      title: 'List'
    })
    popover.show()
    setTimeout(function () { popover.dispose() }, 1500)
  }
}
