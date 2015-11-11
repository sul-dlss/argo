BYTE_ORDERS = %w(B KB MB GB TB PB EB)
class Numeric
  def bytestring(fmt = '%.1f %s')
    order = 0
    order += 1 while (self > 1024**(order + 1))
    fmt % [self.to_f / (1024**order), BYTE_ORDERS[order]]
  end
end
