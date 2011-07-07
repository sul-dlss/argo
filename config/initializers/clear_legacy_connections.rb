unless Rails.configuration.cache_classes
  ActiveSupport.on_load(:active_record) do
    ActionDispatch::Callbacks.after do
      Legacy::Base.clear_reloadable_connections!
    end
  end
end
