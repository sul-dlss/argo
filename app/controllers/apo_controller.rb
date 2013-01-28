class ApoController < ApplicationController

  before_filter :create_obj, :except => [:register]
  #after_filter :redirect, :only => [:delete_collection, :delete_collection, :add_collection, :update_title, :update_creative_commons, :update_use, :update_copyright, :update_default_object_rights, :add_roleplayer, :update_desc_metadata]
  after_filter :save_and_index, :only => [:delete_collection, :delete_collection, :add_collection, :update_title, :update_creative_commons, :update_use, :update_copyright, :update_default_object_rights, :add_roleplayer, :update_desc_metadata]
  
  
  def register
    if params[:title]
      #register a new apo
      
      reg_params={}
      reg_params[:label] = params[:title]
      reg_params[:object_type] = 'adminPolicy'
      reg_params[:admin_policy] = 'druid:hv992ry2431'
      #reg_params[:source_id] = 'apo:'+params[:title]
      response = Dor::RegistrationService.create_from_request(reg_params)
      pid = response[:pid]
      item=Dor.find(pid)
      #item.set_copyright_statement(params[:copyright])
      item.set_use_statement(params[:use])
      item.set_mods_title(params[:title])
      item.set_desc_metadata_format(params[:desc_md])
      if params[:collection] and params[:collection].length > 0
        item.set_default_collection params[:collection]
      end
      #item.set_default_workflow(params[:workflow])
      roleplayers=params[:roleplayer].split ','
      role=params[:role]
      roleplayers.each do |entity|
        item.add_roleplayer role, entity
      end
      item.save
      
      item.update_index
      
      respond_to do |format|
        format.any { redirect_to catalog_path(pid), :notice => 'APO created.' }
      end
      return
    end
  end
  
  def add_roleplayer
    @object.add_roleplayer(params[:role], params[:roleplayer])
    redirect
  end

  def delete_roleplayer
    @object.delete_roleplayer(params[:role], params[:roleplayer])
    redirect
  end

  def delete_collection
    @object.delete_collection(params[:collection])
    redirect
  end
  
  def add_collection
    @object.add_collection(params[:collection])
    redirect
  end

  def update_title
    @object.update_title(params[:title])
    redirect
  end

  def update_creative_commons
    @object.update_creative_commons(params[:creative_commons], creative_commons_options)
    redirect
  end
  
  def update_use
    @object.update_use(params[:use])
    redirect
  end
  
  def update_copyright
    @object.update_copyright(params[:copyright])
    redirect
  end
  
  def update_default_object_rights
    @object.update_default_object_rights(params[:rights])
    redirect
  end
  
  def update_desc_metadata
    @object.update_desc_metadata_format(params[:desc_metadata_format])
    redirect
  end


  private 
  def reindex item
    doc=item.to_solr
    Dor::SearchService.solr.add(doc, :add_attributes => {:commitWithin => 1000})
  end
  def create_obj
    if params[:id]
      @object = Dor.find params[:id], :lightweight => true
      @collections = @object.default_collections
      new_col=[]
      if @collections
        @collections.each do |col|
          new_col << Dor.find(col)
        end
      end
      @collections=new_col
    else
      raise 'missing druid'
    end
  end
  def save_and_reindex
    @object.save
    reindex @object
  end

  def save_and_index
    @object.save
  end
  
  def redirect
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'APO updated.' }
    end
  end

  #check that the user can carry out this item modification
  def forbid
    if not current_user.is_admin and not @object.can_manage_content?(current_user.roles params[:id])
      render :status=> :forbidden, :text =>'forbidden'
      return
    end
  end
end