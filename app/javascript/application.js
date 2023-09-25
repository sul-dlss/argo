// Entry point for the build script in your package.json

import bootstrap from 'bootstrap/dist/js/bootstrap'
import Blacklight from 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight'

import './controllers'

import Argo from './argo'
import '@hotwired/turbo-rails'

global.bootstrap = bootstrap

// TODO: Figure out if the behavior we're altering in this patch is a bug in Blacklight's modal JS.
Blacklight.Modal.modalAjaxLinkClick = (e) => {
  e.preventDefault()
  const href = e.target.closest(`${Blacklight.Modal.triggerLinkSelector}, ${Blacklight.Modal.preserveLinkSelector}`).getAttribute('href')
  fetch(href)
    .then(response => {
      if (!response.ok) {
        throw new TypeError('Request failed')
      }
      return response.text()
    })
    .then(data => Blacklight.Modal.receiveAjax(data))
    .catch(error => Blacklight.Modal.onFailure(error))
}

document.addEventListener('turbo:load', async () => {
  // Start argo after Turbo has been loaded
  new Argo().initialize()
})
