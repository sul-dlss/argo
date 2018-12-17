Blacklight.onLoad(function() {
    // Allows filtering a list of facets.
    $(document).on('keyup', '#filterInput', function(e) {
        const input = document.getElementById('filterInput')
        const filter = input.value.toUpperCase()
        const ul = document.getElementsByClassName('facet-values')[0]
        const li = ul.getElementsByTagName('li')

        // Loop through all list items, and hide those who don't match the search query
        for (let i = 0; i < li.length; i++) {
            const a = li[i].getElementsByTagName("a")[0]
            const txtValue = a.textContent || a.innerText
            if (txtValue.toUpperCase().indexOf(filter) > -1) {
                li[i].style.display = ""
            } else {
                li[i].style.display = "none"
            }
        }
    })
})
