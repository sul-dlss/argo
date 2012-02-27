class Legacy::CropInfo < Legacy::Base
  
  self.table_name = 'crop'
  belongs_to :file, :foreign_key => 'file_id', :primary_key => 'id'
  
  def self.webcrop(value)
    result = self.create
    result.webcrop = value
    result
  end
  
  def x1
    self.x
  end
  
  def x2
    if self.x1.nil?
      nil
    else
      self.x1 + (self.width || self.file.horiz_pixels).to_i
    end
  end
  
  def y1
    self.y
  end
  
  def y2
    if self.y1.nil?
      nil
    else
      self.y1 + (self.height || self.file.vert_pixels).to_i
    end
  end
  
  def rotationAngle
    self.rotate || 0
  end
  
  def webcrop
    result = { :rotationAngle => rotationAngle, :cropCoords => { :x1 => x1, :y1 => y1, :x2 => x2, :y2 => y2 }.reject { |k,v| v.nil? } }.reject { |k,v| v.nil? }
    result.delete(:cropCoords) if result[:cropCoords].empty?
    result
  end
  
  def webcrop=(value)
    update_attribute :rotate, value[:rotationAngle]

    coords = value[:cropCoords]
    if coords.nil?
      update_attributes! :x => nil, :y => nil, :width => nil, :height => nil
    else
      update_attributes! :x => coords[:x1].to_i, :y => coords[:y1].to_i, :width => (coords[:x2].to_i - coords[:x1].to_i), :height => (coords[:y2].to_i - coords[:y1].to_i)
    end
  end
  
end
