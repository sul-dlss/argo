require 'stanford-mods'
module ItemsHelper
  def valid_resource_types type
    valid_types=['object','file']
    if type =~/Book/
      valid_types<<'page'
      valid_types<<'spread'
    end
    if type=~/File/
      valid_types<<'main'
      valid_types<<'supplement'
      valid_types<<'permission'
    end
    if type=~ /Image/
      valid_types<<'image'     
    end 
    return valid_types  
  end
  def stacks_url_full_size obj, file_name
    druid=obj.pid
    Argo::Config.urls.stacks_file+'/'+druid+'/'+file_name
  end

  def mclaughlin_reorder_states xml
    states=[]
    parent=nil
    xml.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      if node['displayLabel'] and node['displayLabel'].include? 'tate'
        states << node
        parent=node.parent
      end 
    end
    sorted=states.sort_by{ |n| if n['displayLabel'].length ==7
      n['displayLabel']
    else
      n['displayLabel'][7]='z' #pad 2 digit numbers so they sort to the bottom. There must be a better way.
    end }
    sorted.each do |node|
      parent << node
    end
    xml
  end

  def mclaughlin_cleanup_notes xml
    xml.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      atts=node.attributes()
      atts.keys.each do |att|
        txt=atts[att].text
        case att
        when 'displayLabel'
          case txt
          when ''
            node.remove_attribute(att)
          when 'general note'
            node.remove_attribute(att)
          when 'general_state_note'
            node.remove_attribute(att)
          when 'state_note'
            node.remove_attribute(att)
          when 'state note'
            node.remove_attribute(att)
          end
        when 'type'
          case txt
          when 'content'
            node.remove_attribute(att)
          when ' '
            node.remove_attribute(att)            
          when ''
            node.remove_attribute(att)
          when 'state_note'
            node.remove_attribute(att)
          end
        end
      end
    end
  end
  def mclaughlin_cleanup_statement xml
    xml.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      atts=node.attributes()
      statement=false
      if node['displayLabel']=='' and node['type']=='statement_of_responsibility'
        statement=true
      end
      if node['displayLabel']=='state_node_1' and node['type']=='statement_of_responsibility'
        statement=true
      end
      if node['displayLabel']=='state_note' and node['type']=='statement_of_responsibility'
        statement=true
      end
      if node['displayLabel']=='statement of responsibility'
        statement=true
      end
      if node['type']=='statement_of_responsibility'
        statement=true
      end
      if statement
        node['displayLabel']='Statement of responsibility'
        node['type']='statement_of_responsibility'
      end
    end
  end
  def mclaughlin_cleanup_publication xml
    xml.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      atts=node.attributes()
      pub=false
      if node['displayLabel']=='' and node['type']=='publications'
        pub=true
      end
      if node['displayLabel']=='general note' and node['type']=='publications'
        pub=true
      end
      if node['displayLabel']=='state_note' and node['type']=='publications'
        pub=true
      end
      if pub
        node['displayLabel']='Publications'
        node['type']='publications'
      end
    end
  end
  def mclaughlin_cleanup_references xml
    xml.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      atts=node.attributes()
      ref=false
      if node['displayLabel']=='' and node['type']=='references'
        ref=true
      end
      if node['displayLabel']=='general note' and node['type']=='references'
        ref=true
      end
      if node['displayLabel']=='general note' and node['type']=='reference'
        ref=true
      end
      if node['displayLabel']=='citation/reference' and node['type']==nil
        ref=true
      end
      if ref
        node['displayLabel']='References'
        node['type']='reference'
      end
    end
  end     
  def mclaughlin_cleanup_states xml
    xml.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      atts=node.attributes()
      states=false
      if node['type'] and node['type'].include?('state') and is_numeric?(node['type'][-1, 1]) 
        #find the number and use it
        number=node['type'][-2, 2].strip
        if not is_numeric? number
          number=node['type'][-1, 1]
        end       
        node['displayLabel']='State '+number
        node.remove_attribute('type')
      else
        if node['displayLabel'] and (node['displayLabel'].include?('State') or node['displayLabel'].include?('state')) and is_numeric? node['displayLabel'][-1][1]
          number=node['displayLabel'][-2, 2].strip
          if not is_numeric? number
            number=node['displayLabel'][-1, 1]
          end
          if not is_numeric? number
            node.remove_attribute('displayLabel')
            node.remove_attribute('type')
          else
            node['displayLabel']='State '+number
            node.remove_attribute('type')
          end
        end
      end
    end
  end
  def mclaughlin_ignore_fields xml
    xml.search('//mods:note[@displayLabel=\'location_code\']','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      node.remove
    end
  end
  def mclaughlin_fix_subjects xml
    xml.search('//mods:subject','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      #if there is more than 1 topic in this subject, split it out into another subject
      topics = node.search('//mods:topic','mods'=>'http://www.loc.gov/mods/v3')
      if topics.length > 1
        parent=node.parent
        node.remove
        topics.each do |topic|
          new_sub=Nokogiri::XML::Node.new('mods:subject',xml)
          parent.add_child(new_sub)
          topic.parent = new_sub
        end
      end
    end
  end

  #order the children of cartographics nodes, because ordering matters and mdtoolkit doesnt do it right.
  def mclaughlin_reorder_cartographics xml
    xml.search('//mods:cartographics','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      children=node.children
      ['scale', 'projection', 'coordinates'].each do |child|
        children.each do|chi|
          if chi.name == child
            node << chi
          end
        end
      end
    end
  end

  def schema_validate xml
    @xsd ||= Nokogiri::XML::Schema(File.read(File.expand_path(File.dirname(__FILE__) + "/xslt/mods-3-4.xsd")))
    errors=[]
    if @xsd.valid? xml
    else
      @xsd.validate(xml).each do |er|
        errors <<  er.message
      end
    end
    errors
  end

  def mclaughlin_prune_identifiers xml
    xml.search('//mods:identifier','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      text=node['displayLabel']
      case text
      when 'Original McLaughlin book number (1995 edition) with latest state information'
        #node.remove
      when 'Original McLaughlin book number (1995 edition)'
        #node.remove
      when 'Updated McLaughlin Book Number'
        #node.remove
      when 'Updated McLaughlin Book Number with latest state information'
        #node.remove
      when 'Post publication map number'
        #node.remove
      when 'Post publication map number with latest state information'
        #node.remove
      when 'FileMaker Pro Record Number'
        node.remove
      when 'FileMaker Pro record number with latest state information'
        node.remove
      when 'Stanford University Archives Id'
        node.remove
      when 'New Stanford map number'
        node.remove
      when 'New Stanford map number with latest state information'
        node.remove
      when 'SU DRUID'
        node.remove
      when 'entry_number'
        node.remove
      when 'call_number'
        node.remove
      when 'book_number'
        node.remove
      when 'record_number'
        node.remove
      when 'filename'
        node.remove
      end
    end
  end
  def is_blank?(node)
    all_children_are_blank?(node) and (node.text? and node.content.strip == '')
  end
  def all_children_are_blank?(node)
    toret=true
    node.children.all?{|child| 
      #this needs to be sure to return the correct value
      c=is_blank?(child)
      if c
        child.remove
      else
        toret=false
      end
    }
    toret 
  end
  #remove empty nodes and strip trailing whitespace from text
  def remove_empty_nodes xml
    root=xml.search('//mods:mods','mods'=>'http://www.loc.gov/mods/v3')
    nodes_to_remove=[]
    text=''
    #this is necissary because the node remeoval really needs to happen from the bottom up, and traverse is top down. There should be a better way.
    while text!=xml.to_s
      text=xml.to_s
      if root.length>0
        root.first.traverse {|node| 
          if all_children_are_blank?(node) and node.name != 'text' and node.name != 'typeOfResource'
            nodes_to_remove << node
          else
            if node.name=='text'
              node.content=node.content.strip
            end
            node.attributes.keys.each do |att| 
              if node[att]==' ' or node[att]== '' and att != 'text'
                node.attributes[att].remove
              end
            end
          end
        }
        nodes_to_remove.each do |node|
          node.remove
        end
      end
    end
  end
  def mclaughlin_remove_newlines xml
    xml.search('//mods:accessCondition','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      node.content=node.text.gsub(/\n\s*/,'')
    end
  end

  def mods_discoverabable xml
    messages=[]
    mods_rec = Stanford::Mods::Record.new
    mods_rec.from_nk_node(xml)
    #should have a title
    title=mods_rec.sw_full_title
    if title and title.length>0
    else
      messages<< 'Missing title.'
    end
    #should have a dateIssued
    vals = mods_rec.term_values([:origin_info,:dateIssued])
    if vals
      vals = vals.concat mods_rec.term_values([:origin_info,:dateCreated]) unless not mods_rec.term_values([:origin_info,:dateCreated])
    else
      vals = mods_rec.term_values([:origin_info,:dateCreated])
    end
    if vals and vals.length>0
    else
      messages << "Missing dateIssued or dateCreated."
    end
    #should have a typeOfResource
    good_formats=['still image', 'mixed material', 'moving image', 'three dimensional object', 'cartographic', 'sound recording-musical', 'sound recording-nonmusical', 'software, multimedia']
    format=mods_rec.term_values(:typeOfResource)
    if format and format.length>0 and good_formats.include? format.first 
    else
      messages << 'Missing or invalid typeOfResource'
    end
    messages
  end
  def mclaughlin_remediation xml
    mclaughlin_reorder_states xml
    mclaughlin_cleanup_notes xml
    mclaughlin_remove_newlines xml
    mclaughlin_prune_identifiers xml
    mclaughlin_reorder_cartographics xml
    mclaughlin_fix_subjects xml
    remove_empty_nodes xml
    mclaughlin_ignore_fields xml
    mclaughlin_cleanup_references xml
    mclaughlin_cleanup_publication xml
  end
  def is_numeric? s
    begin
      Float(s)
    rescue
      false # not numeric
    else
      true # numeric
    end
  end
end
