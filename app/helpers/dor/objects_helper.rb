module Dor::ObjectsHelper

  def class_for(object_type)
    case object_type
    when 'item'         then Dor::Item
    when 'admin_policy' then Dor::AdminPolicyObject
    else                     Dor::Base
    end
  end
  
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
