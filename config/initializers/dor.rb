module Dor
  module Editable
    def agreement=(val)
      self.agreement_object = Dor.find(val.to_s)
    end
  end
end
