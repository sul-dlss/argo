import autocomplete from 'autocomplete.js'

export default class {
  newHitsSource(params) {
    return function doSearch(query, cb) {
      fetch(`/registration/suggest_project?term=${query}`)
        .then(response => response.json())
        .then(res => cb(res))
    }
  }

  initialize() {
    autocomplete('[data-project-autocomplete]', { minLength: 2 }, [
      {
        source: this.newHitsSource({ hitsPerPage: 5 }),
        displayKey: (suggestion) => suggestion,
      }
    ]).on('autocomplete:selected', function(event, suggestion, dataset, context) {
      // console.log(event, suggestion, dataset, context);
    });
  }
}
