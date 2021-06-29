import { Application } from 'stimulus'
import CollectionEditor from 'controllers/collection_editor'
import BulkActions from 'controllers/bulk_actions'
import BulkUpload from 'controllers/bulk_upload'
import FacetFilter from 'controllers/facet_filter'
import JSONRenderer from 'controllers/json_renderer'
import Tokens from 'controllers/tokens'
import WorkflowGrid from 'controllers/workflow_grid_controller'
import BlacklightHierarchyController from 'blacklight-hierarchy/app/assets/javascripts/blacklight/hierarchy/blacklight_hierarchy_controller'
import NestedFormController from 'controllers/nested_form_controller'

const application = Application.start()
application.register("bulk_actions", BulkActions)
application.register("bulk_upload", BulkUpload)
application.register("facet-filter", FacetFilter)
application.register('json-renderer', JSONRenderer)
application.register("workflow-grid", WorkflowGrid)
application.register("collection-editor", CollectionEditor)
application.register("tokens", Tokens)
application.register("b-h-collapsible", BlacklightHierarchyController)
application.register("nested-form", NestedFormController)
