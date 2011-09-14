module DocumentHelper

  # TODO: Remove this after all documents are reindexed with id instead of PID
  def render_document_index_label *args
    super(*args).to_s
  end
  
  def render_index_field_value args
    if args[:field] == 'PID'
      val = args[:document].get(args[:field])
      link_to val, File.join(Dor::Config.fedora.safeurl, "objects/#{val}"), :class => 'ext-link', :target => 'dor', :title => 'View in DOR'
    else
      super(args)
    end
  end
  
  def render_document_show_field_value args
    if args[:field] == 'PID'
      val = args[:document].get(args[:field])
      link_to val, File.join(Dor::Config.fedora.safeurl, "objects/#{val}"), :class => 'ext-link', :target => 'dor', :title => 'View in DOR'
    else
      super(args)
    end
  end
  
end
