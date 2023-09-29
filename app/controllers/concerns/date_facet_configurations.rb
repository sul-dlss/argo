# frozen_string_literal: true

module DateFacetConfigurations
  extend ActiveSupport::Concern

  module ClassMethods
    def add_common_date_facet_fields_to_config!(config)
      # Be careful using NOW: http://lucidworks.com/blog/date-math-now-and-filter-queries/
      # tl;dr: specify coarsest granularity (/DAY or /HOUR) or lose caching
      #
      # TODO: update blacklight_range_limit to work w/ dates and use it.  Or something similarly powerful.
      #      Per-query user-paramatized facet endpoints w/ auto-scaling granularity is the point.
      #      See solr facet ranges (start/end/gap), NOT facet range queries (fq), as here.
      config.add_facet_field "registered_date", home: false, label: "Registered",
        component: DateChoiceFacetComponent,
        query: {
          all: {label: "All", fq: "#{SolrDocument::FIELD_REGISTERED_DATE}:*"},
          days_7: {label: "within 7 days", fq: "#{SolrDocument::FIELD_REGISTERED_DATE}:[NOW/DAY-7DAYS TO *]"},
          days_30: {label: "within 30 days", fq: "#{SolrDocument::FIELD_REGISTERED_DATE}:[NOW/DAY-30DAYS TO *]"}
        }, raw_facet_field: SolrDocument::FIELD_REGISTERED_DATE
      config.add_facet_field SolrDocument::FIELD_REGISTERED_DATE, label: "Registered", if: false, home: false

      config.add_facet_field "accessioned_latest_date", home: false, label: "Last Accessioned",
        component: DateChoiceFacetComponent,
        query: {
          all: {label: "All", fq: "#{SolrDocument::FIELD_LAST_ACCESSIONED_DATE}:*"},
          days_7: {label: "within 7 days", fq: "#{SolrDocument::FIELD_LAST_ACCESSIONED_DATE}:[NOW/DAY-7DAYS TO *]"},
          days_30: {label: "within 30 days", fq: "#{SolrDocument::FIELD_LAST_ACCESSIONED_DATE}:[NOW/DAY-30DAYS TO *]"}
        }, raw_facet_field: SolrDocument::FIELD_LAST_ACCESSIONED_DATE
      config.add_facet_field SolrDocument::FIELD_LAST_ACCESSIONED_DATE, label: "Last Accessioned", if: false, home: false

      config.add_facet_field "accessioned_earliest_date", home: false, label: "Earliest Accessioned",
        component: DateChoiceFacetComponent,
        query: {
          all: {label: "All", fq: "#{SolrDocument::FIELD_EARLIEST_ACCESSIONED_DATE}:*"},
          days_1: {label: "within the last day", fq: "#{SolrDocument::FIELD_EARLIEST_ACCESSIONED_DATE}:[NOW/DAY-1DAYS TO *]"},
          days_7: {label: "within 7 days", fq: "#{SolrDocument::FIELD_EARLIEST_ACCESSIONED_DATE}:[NOW/DAY-7DAYS TO *]"},
          days_30: {label: "within 30 days", fq: "#{SolrDocument::FIELD_EARLIEST_ACCESSIONED_DATE}:[NOW/DAY-30DAYS TO *]"},
          days_365: {label: "within the last year",
                     fq: "#{SolrDocument::FIELD_EARLIEST_ACCESSIONED_DATE}:[NOW/DAY-365DAYS TO *]"}
        }, raw_facet_field: SolrDocument::FIELD_EARLIEST_ACCESSIONED_DATE
      config.add_facet_field SolrDocument::FIELD_EARLIEST_ACCESSIONED_DATE, label: "Earliest Accessioned", if: false, home: false

      config.add_facet_field 'published_latest_date', home: false, label: 'Last Published',
                                                      component: DateChoiceFacetComponent,
                                                      query: {
                                                        days_7: { label: 'within 7 days',
                                                                  fq: "#{SolrDocument::FIELD_LAST_PUBLISHED_DATE}:[NOW/DAY-7DAYS TO *]" },
                                                        days_30: { label: 'within 30 days',
                                                                   fq: "#{SolrDocument::FIELD_LAST_PUBLISHED_DATE}:[NOW/DAY-30DAYS TO *]" }
                                                      }, raw_facet_field: SolrDocument::FIELD_LAST_PUBLISHED_DATE
      config.add_facet_field SolrDocument::FIELD_LAST_PUBLISHED_DATE, label: 'Last Published', if: false, home: false

      config.add_facet_field 'object_modified_date', home: false, label: 'Last Modified',
                                                     component: DateChoiceFacetComponent,
                                                     query: {
                                                       days_7: { label: 'within 7 days',
                                                                 fq: "#{SolrDocument::FIELD_LAST_MODIFIED_DATE}:[NOW/DAY-7DAYS TO *]" },
                                                       days_30: { label: 'within 30 days',
                                                                  fq: "#{SolrDocument::FIELD_LAST_MODIFIED_DATE}:[NOW/DAY-30DAYS TO *]" }
                                                     }, raw_facet_field: SolrDocument::FIELD_LAST_MODIFIED_DATE

      config.add_facet_field SolrDocument::FIELD_LAST_MODIFIED_DATE, label: 'Last Modified', if: false, home: false

      config.add_facet_field 'version_opened_date', home: false, label: 'Last Opened',
                                                    component: DateChoiceFacetComponent,
                                                    query: {
                                                      all: { label: 'All',
                                                             fq: "#{SolrDocument::FIELD_LAST_OPENED_DATE}:*" },
                                                      days_7: { label: 'more than 7 days',
                                                                fq: "#{SolrDocument::FIELD_LAST_OPENED_DATE}:[* TO NOW/DAY-7DAYS]" },
                                                      days_30: { label: 'more than 30 days',
                                                                 fq: "#{SolrDocument::FIELD_LAST_OPENED_DATE}:[* TO NOW/DAY-30DAYS]" }
                                                    }, raw_facet_field: SolrDocument::FIELD_LAST_OPENED_DATE
      config.add_facet_field SolrDocument::FIELD_LAST_OPENED_DATE, label: 'Last Opened', if: false, home: false

      config.add_facet_field 'embargo_release_date', home: false, label: 'Embargo Release Date',
                                                     component: DateChoiceFacetComponent,
                                                     query: {
                                                       days_7: { label: 'up to 7 days',
                                                                 fq: "#{SolrDocument::FIELD_EMBARGO_RELEASE_DATE}:[NOW TO NOW/DAY+7DAYS]" },
                                                       days_30: { label: 'up to 30 days',
                                                                  fq: "#{SolrDocument::FIELD_EMBARGO_RELEASE_DATE}:[NOW TO NOW/DAY+30DAYS]" },
                                                       all: { label: 'All',
                                                              fq: "#{SolrDocument::FIELD_EMBARGO_RELEASE_DATE}:*" }
                                                     }, raw_facet_field: SolrDocument::FIELD_EMBARGO_RELEASE_DATE
      config.add_facet_field SolrDocument::FIELD_EMBARGO_RELEASE_DATE, label: 'Embargo Release Date', if: false,
                                                                       home: false
    end
  end
end
