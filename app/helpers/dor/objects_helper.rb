module Dor::ObjectsHelper

  def merge_params(hash)
    # convert camelCase parameter names to under_score, and string keys to symbols
    # e.g., 'objectType' to :object_type
    hash.each_pair { |k,v| 
      key = k.underscore
      params[key.to_sym] = v
    }
  end

  def ids_to_hash(ids)
    if ids.nil?
      nil
    else
      Hash[Array(ids).collect { |id| id.split(/:/) }]
    end
  end
    
end
