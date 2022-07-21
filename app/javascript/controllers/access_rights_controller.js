import { Controller } from 'stimulus'

// This handles editing the access rights for a DRO
export default class extends Controller {
  static targets = ["view", "download", "location", "cdl", "downloadRow", "locationRow", "cdlRow"]

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
      return this.enableCdl()

    this.disableCdl()

    // This has to come after enableDownload
    this.activateWorldDownload(false)
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

  worldDownloadOption() {
    return this.downloadTarget.querySelector('[value="world"]')
  }

  stanfordDownloadOption() {
    return this.downloadTarget.querySelector('[value="stanford"]')
  }
  // **
  // * @param {bool} state If true, then the World option can be selected
  activateWorldDownload(state) {
    const option = this.worldDownloadOption()
    option.disabled = !state
    if (!state)
      option.selected = false
  }

  // **
  // * @param {bool} state If true, then the Stanford option can be selected
  activateStanfordDownload(state) {
    const option = this.stanfordDownloadOption()
    option.disabled = !state
    if (!state)
      option.selected = false
  }

  // **
  // * @param {bool} forLocation If true, then the download menu prevents World or Stanford from being selected.
  enableDownload(forLocation) {
    this.activateWorldDownload(!forLocation)
    this.activateStanfordDownload(!forLocation)

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
    // Set this to false, so that it gets updated when we merge the params
    // from the form with those in the cocina-model
    this.cdlTarget.value = false
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
