import TagsAutocomplete from './modules/tags_autocomplete'
import ProjectAutocomplete from './modules/project_autocomplete'

require('@github/time-elements')

export default class Argo {
  initialize () {
    this.tagsAutocomplete()
    this.projectAutocomplete()
  }

  tagsAutocomplete () {
    new TagsAutocomplete().initialize()
  }

  projectAutocomplete () {
    new ProjectAutocomplete().initialize()
  }
}
