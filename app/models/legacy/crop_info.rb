class Legacy::CropInfo < Legacy::Base
  set_table_name 'crop'
  belongs_to :file, :foreign_key => 'file_id', :primary_key => 'id'
  
  def x1
    self.x || 0
  end
  
  def x2
    self.x1 + (self.width || self.file.horiz_pixels).to_i
  end
  
  def y1
    self.y || 0
  end
  
  def y2
    self.y1 + (self.height || self.file.vert_pixels).to_i
  end
  
  def rotationAngle
    self.rotate || 0
  end
  
  def webcrop
    { :rotationAngle => rotationAngle, :cropCoords => { :x1 => x1, :y1 => y1, :x2 => x2, :y2 => y2 } }
  end
  
  def webcrop=(value)
    set_attributes :x => value[:x1], :y => value[:y1], :width => (value[:x2] - value[:x1]), :height => (value[:y2] - value[:y1]), :rotate => value[:rotationAngle]
  end
  
end
