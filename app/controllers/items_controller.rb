class ItemsController < ApplicationController

  def crop
    @druid = params[:id].sub(/^druid:/,'')
    files = Legacy::Object.find_by_druid(@druid).files.find_all_by_file_role('02').sort { |a,b| a.id <=> b.id }
    @image_data = files.collect do |file|
      hash = { :origHeight => file.vert_pixels, :origWidth => file.horiz_pixels, :fileSrc => "https://sul-dl-dlib7.stanford.edu/image.rb?id=#{file.id}" }
      unless file.crop_info.nil?
        hash.merge!(file.crop_info.webcrop)
      end
      hash
    end
    render :crop, :layout => false
  end
  
  def register
    render :register
  end
  
end
