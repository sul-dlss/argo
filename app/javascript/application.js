// Entry point for the build script in your package.json

import 'jquery' // Blacklight 7 needs jQuery. Remove when we upgrade to Blacklight 8?
import bootstrap from 'bootstrap/dist/js/bootstrap' // Required for Blacklight 7 so it can manage the modals

import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight'
import './controllers'

import Argo from './argo'
import '@hotwired/turbo-rails'
global.bootstrap = bootstrap

document.addEventListener('turbo:load', async () => {
  // Start argo after Turbo has been loaded
  new Argo().initialize()
})

document.addEventListener('turbo:before-fetch-response', async (event) => {
  const response = event.detail.fetchResponse.response
  const tokenExpired = response.status === 401 && await response.text() === 'authentication expired'
  const shibbolethExpired = response.status === 302 && response.headers.get('Location').startsWith('https://login.stanford.edu/')
  if (tokenExpired || shibbolethExpired) {
    console.dir(event.detail)
    alert('Your session has expired. The page will be refreshed.')
    window.location.reload()
  }
})

document.addEventListener('turbo:fetch-request-error', async (event) => {
  console.dir(event.detail)
  alert('A network error occurred, possibly because your session has expired. The page will be refreshed.')
  window.location.reload()
})
