class ItemsController < ApplicationController

  def crop
    @druid = params[:id].sub(/^druid:/,'')
    files = Legacy::Object.find_by_druid(@druid).files.find_all_by_file_role('00').sort { |a,b| a.id <=> b.id }
    @image_data = files.collect do |file|
      src_file = file.alternate('02') || file.alternate('01') || file
      hash = { 
        :origHeight => file.vert_pixels, 
        :origWidth => file.horiz_pixels, 
        :fileSrc => "#{ENV['RACK_BASE_URI']}/images/.dpg_pool/#{src_file.file_name}",
        :fileName => File.basename(file.file_name)
      }
      unless file.crop_info.nil?
        hash.merge!(file.crop_info.webcrop)
      end
      hash
    end
    render :crop, :layout => 'webcrop'
  end
  
  def register
    render :register
  end
  
end
