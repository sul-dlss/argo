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
  
  def hierarchy(k, v, field_name, path)
    result = path.nil? ? k : (link_to k, %{#{Dor::Config.gsearch.url}/select?q=#{field_name}:"#{path}"})
    count, subset = v.is_a?(Hash) ? [nil, v] : Array(v)
    result << " (#{count})" unless count.nil?
    unless subset.nil?
      subset.keys.select { |p| p.is_a?(String) }.sort.each { |k1| 
        v1 = subset[k1]
        result << (ul hierarchy(k1, v1, field_name, [path,k1].compact.join(':')))
      }
    end
    result
  end

  def workflow_facets(params)
    query_params = params.merge({:rows => '0', :facet => 'on', :'facet.field' => ['wf_wps_facet', 'wf_wsp_facet', 'wf_swp_facet'],
      :'facet.mincount' => 1, :'facet.limit' => -1 })
    puts query_params.inspect
    resp = Dor::SearchService.gsearch(query_params)
    puts resp.inspect
    raw = resp['facet_counts']['facet_fields']
    hash = {}
    raw.each_pair { |wf,data|
      hash[wf] ||= {}
      h = Hash[*data]
      h.each_pair { |k,v|
        path = k.split(/:/)
        loc = hash[wf]
        while path.length > 0
          loc = loc[path.shift] ||= {}
        end
        loc[:_] = v
      }
    }
    cleanup_workflow_facets(hash)
  end

  private
  def cleanup_workflow_facets(h)
    h.each_pair { |k,v| 
      count = v.delete(:_)
      if v.empty?
        h[k] = count
      elsif count.nil?
        h[k] = cleanup_workflow_facets(v)
      else
        h[k] = [count, cleanup_workflow_facets(v)]
      end
    }
    h
  end
  
end
