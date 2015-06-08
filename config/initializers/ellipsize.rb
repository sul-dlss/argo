class String
  # remove middle from strings exceeding max length.
  def ellipsize(options={})
    max = options[:max] || 40
    delimiter = options[:delimiter] || "..."
    return self if self.size <= max
    remainder = max - delimiter.size
    offset = remainder / 2
    (self[0,offset + (remainder.odd? ? 1 : 0)].to_s + delimiter + self[-offset,offset].to_s)[0,max].to_s
  end unless defined? ellipsize
end
