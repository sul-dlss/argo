import { Controller } from '@hotwired/stimulus'

// This handles editing the access rights for a DRO
export default class extends Controller {
  static targets = [
    'view',
    'download',
    'location',
    'downloadRow',
    'locationRow'
  ]

  connect () {
    this.render()
  }

  // Called when the view menu changes
  updateView () {
    this.render()
  }

  // Called when the download menu changes
  updateDownload () {
    this.render()
  }

  render () {
    switch (this.currentView()) {
      case 'dark':
      case 'citation-only':
        this.setCitationOrDark()
        break
      case 'location-based':
        this.setLocationBasedView()
        break
      case 'stanford':
        this.setStanfordView()
        break
      case 'world':
        this.setWorldView()
        break
    }
  }

  setCitationOrDark () {
    this.disableDownload()
    this.disableLocation()
  }

  setWorldView () {
    this.enableDownload(false)
    this.maybeEnableLocation()
  }

  setLocationBasedView () {
    this.enableDownload(true)
  }

  setStanfordView () {
    this.enableDownload(false)
    this.maybeEnableLocation()

    // This has to come after enableDownload
    this.activateWorldDownload(false)
  }

  maybeEnableLocation () {
    if (this.currentDownload() === 'location-based') {
      this.enableLocation()
    } else {
      this.disableLocation()
    }
  }

  downloadDropDown () {
    const downloadDropDown = document.getElementById('item_download_access')
    if (downloadDropDown === null) {
      return document.getElementById('embargo_download_access')
    }

    return downloadDropDown
  }

  disableDownload () {
    // ** Reset the download dropdown
    // * - This forces the download to change to blank when selecting disabled
    const downloadDropDown = this.downloadDropDown()
    const selectedDownloadIndex = downloadDropDown.options.selectedIndex
    downloadDropDown.options[selectedDownloadIndex].removeAttribute('selected')
    downloadDropDown.options[3].setAttribute('selected', 'selected')
    this.downloadTarget.value = 'none'
    this.downloadRowTarget.hidden = true
    this.downloadTarget.disabled = true
  }

  worldDownloadOption () {
    return this.downloadTarget.querySelector('[value="world"]')
  }

  stanfordDownloadOption () {
    return this.downloadTarget.querySelector('[value="stanford"]')
  }

  // **
  // * @param {bool} state If true, then the World option can be selected
  activateWorldDownload (state) {
    const option = this.worldDownloadOption()
    option.disabled = !state
    if (!state) {
      option.selected = false
    }
  }

  // * @param {bool} state If true, then the Stanford option can be selected
  activateStanfordDownload (state) {
    const option = this.stanfordDownloadOption()
    option.disabled = !state
    if (!state) {
      option.selected = false
    }
  }

  // **
  // * @param {bool} forLocation If true, then the download menu prevents World or Stanford from being selected.
  enableDownload (forLocation) {
    this.activateWorldDownload(!forLocation)
    this.activateStanfordDownload(!forLocation)

    this.downloadRowTarget.hidden = false
    this.downloadTarget.disabled = false
  }

  disableLocation () {
    // ** Reset the location dropdown
    // * - This forces the location to change to blank when selecting non location-based rights
    const locationDropDown = this.locationDropDown()
    const selectedLocationIndex = locationDropDown.options.selectedIndex
    locationDropDown.options[selectedLocationIndex].removeAttribute('selected')
    locationDropDown.options[0].setAttribute('selected', 'selected')
    this.locationTarget.value = null
    this.locationRowTarget.hidden = true
    this.locationTarget.disabled = true
  }

  locationDropDown () {
    const locationDropDown = document.getElementById('item_access_location')
    if (locationDropDown === null) {
      return document.getElementById('embargo_access_location')
    }

    return locationDropDown
  }

  enableLocation () {
    this.locationRowTarget.hidden = false
    this.locationTarget.disabled = false
  }

  currentView () {
    return this.viewTarget.selectedOptions[0].value
  }

  currentDownload () {
    return this.downloadTarget.selectedOptions[0].value
  }
}
