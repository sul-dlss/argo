import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
    static targets = [ "queryField", "afterDate", "beforeDate" ]

    updateQuery(event) {
        const afterDate = this.afterDateTarget.value
        const beforeDate = this.beforeDateTarget.value
        let query = '[';
        if (afterDate.length > 0) {
          query += new Date(Date.parse(afterDate)).toISOString() + ' TO ';
        } else {
          query += '* TO ';
        }
        if (beforeDate.length > 0) {
          // Add the selected date + 23 hours, 59 minutes, 59 seconds
          query += new Date(Date.parse(beforeDate) + 86399000)
            .toISOString() + ']';
        } else {
          query += '*]';
        }
        this.queryFieldTarget.value = query
    }
}
