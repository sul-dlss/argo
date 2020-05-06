# frozen_string_literal: true

Dor.configure do
  if Settings.ssl
    ssl do
      cert_file Settings.ssl.cert_file
      key_file Settings.ssl.key_file
      key_pass Settings.ssl.key_pass
    end
  end

  fedora do
    url Settings.fedora_url
  end

  solr do
    url Settings.solrizer_url
  end

  suri do
    mint_ids     Settings.suri.mint_ids
    id_namespace Settings.suri.id_namespace
    url          Settings.suri.url
    user         Settings.suri.user
    pass         Settings.suri.pass
  end

  stacks do
    local_workspace_root Settings.stacks.local_workspace_root
  end
end
