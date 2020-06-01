import { Controller } from 'stimulus'

export default class extends Controller {
    static targets = [ "list" ]

    filter(event) {
        var filter = event.target.value.toUpperCase();
        var li = this.listTarget.getElementsByTagName('li');

        // Loop through all list items, and hide those who don't match the search query
        for (var i = 0; i < li.length; i++) {
            var a = li[i].getElementsByTagName("a")[0];
            var txtValue = a.textContent || a.innerText;
            if (txtValue.toUpperCase().indexOf(filter) > -1) {
                li[i].style.display = "";
            } else {
                li[i].style.display = "none";
            }
        }
    }
}
