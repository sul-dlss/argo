module Dor
  module Editable
    def agreement
      if agreement_object
        agreement_object.pid
      else
        ''
      end
    end
  end
end
