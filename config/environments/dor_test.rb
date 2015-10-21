Dor.configure do

  fedora do
    url Settings.FEDORA_URL
  end

  workflow do
    url Settings.WORKFLOW_URL
  end

  dor_services do
    url Settings.DOR_SERVICES_URL
  end

  solrizer.url Settings.SOLRIZER_URL

  gsearch do
    url      Settings.GSEARCH_URL
    rest_url Settings.GSEARCH_REST_URL
  end

  suri do
    mint_ids     Settings.SURI.MINT_IDS
    id_namespace Settings.SURI.ID_NAMESPACE
    url          Settings.SURI.URL
    user         Settings.SURI.USER
    pass         Settings.SURI.PASS
  end

  metadata do
    exist.url   Settings.METADATA.EXIST_URL
    catalog.url Settings.METADATA.CATALOG_URL
  end

  content do
    content_user     Settings.CONTENT.USER
    content_base_dir Settings.CONTENT.BASE_DIR
    content_server   Settings.CONTENT.SERVER_HOST
  end
end
