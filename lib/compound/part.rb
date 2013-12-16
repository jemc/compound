
module Compound
  
  class Part
    def method_missing sym, *args, &block
      @_compound_component_parent.send sym, *args, &block
    end
    
    def initialize parent, component_module
      @_compound_component_parent = parent
      extend component_module
    end
  end
  
end
