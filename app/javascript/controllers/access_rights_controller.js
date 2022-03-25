import { Controller } from 'stimulus'

// This handles editing the access rights for a DRO
export default class extends Controller {
  static targets = [ "view", "download", "location", "cdl", "downloadRow", "locationRow", "cdlRow"]

  connect() {
    this.render()
  }

  // Called when the view menu changes
  updateView() {
    this.render()
  }

  // Called when the download menu changes
  updateDownload() {
    this.render()
  }

  render() {
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

  setCitationOrDark() {
    this.disableDownload()
    this.disableLocation()
    this.disableCdl()
  }

  setWorldView() {
    this.enableDownload(false)
    this.maybeEnableLocation()
    this.disableCdl()
  }

  setLocationBasedView() {
    this.enableDownload(true)
    this.enableLocation()
    this.disableCdl()
  }

  setStanfordView() {
    this.enableDownload(false)
    this.maybeEnableLocation()

    if (this.currentDownload() == 'none')
      this.enableCdl()
    else
      this.disableCdl()
  }

  maybeEnableLocation() {
    if (this.currentDownload() == 'location-based')
      this.enableLocation()
    else
      this.disableLocation()
  }

  disableDownload() {
    this.downloadRowTarget.hidden = true
    this.downloadTarget.disabled = true
  }

  // **
  // * @param {bool} forLocation If true, then the download menu prevents World or Stanford from being selected.
  enableDownload(forLocation) {
    const world = this.downloadTarget.querySelector('[value="world"]')
    const stanford = this.downloadTarget.querySelector('[value="stanford"]')
    world.disabled = forLocation
    stanford.disabled = forLocation

    if (forLocation) {
      world.selected = false
      stanford.selected = false
    }

    this.downloadRowTarget.hidden = false
    this.downloadTarget.disabled = false
  }

  disableLocation() {
    this.locationRowTarget.hidden = true
    this.locationTarget.disabled = true
  }

  enableLocation() {
    this.locationRowTarget.hidden = false
    this.locationTarget.disabled = false
  }

  disableCdl() {
    this.cdlRowTarget.hidden = true
    this.cdlTarget.disabled = true
  }

  enableCdl() {
    this.cdlRowTarget.hidden = false
    this.cdlTarget.disabled = false
  }

  currentView() {
    return this.viewTarget.selectedOptions[0].value
  }

  currentDownload() {
    return this.downloadTarget.selectedOptions[0].value
  }
}
