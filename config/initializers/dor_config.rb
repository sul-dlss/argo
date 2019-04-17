# frozen_string_literal: true

Dor.configure do
  ssl do
    cert_file Settings.SSL.CERT_FILE
    key_file Settings.SSL.KEY_FILE
    key_pass Settings.SSL.KEY_PASS
  end if Settings.SSL

  fedora do
    url Settings.FEDORA_URL
  end

  solr do
    url Settings.SOLRIZER_URL
  end

  workflow do
    url Settings.WORKFLOW_URL
    logfile Settings.WORKFLOW.LOGFILE
    shift_age Settings.WORKFLOW.SHIFT_AGE
  end

  dor_services do
    url Settings.DOR_SERVICES.URL
    user Settings.DOR_SERVICES.USER
    pass Settings.DOR_SERVICES.PASS
  end

  suri do
    mint_ids     Settings.SURI.MINT_IDS
    id_namespace Settings.SURI.ID_NAMESPACE
    url          Settings.SURI.URL
    user         Settings.SURI.USER
    pass         Settings.SURI.PASS
  end

  metadata do
    catalog.url Settings.METADATA.CATALOG_URL
    catalog.user Settings.METADATA.CATALOG_USER
    catalog.pass Settings.METADATA.CATALOG_PASS
  end

  content do
    content_user     Settings.CONTENT.USER
    content_base_dir Settings.CONTENT.BASE_DIR
    content_server   Settings.CONTENT.SERVER_HOST
  end

  stacks do
    document_cache_host         Settings.STACKS.DOCUMENT_CACHE_HOST
    document_cache_user         Settings.STACKS.DOCUMENT_CACHE_USER
    local_workspace_root        Settings.STACKS.LOCAL_WORKSPACE_ROOT
    host                        Settings.STACKS.HOST
    user                        Settings.STACKS.USER
  end

  dor_indexing_app do
    url Settings.DOR_INDEXING_URL
  end

  purl_services do
    url Settings.purl_services_url
  end
end
