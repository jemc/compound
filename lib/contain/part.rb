
module Contain
  
  class Part
    def method_missing sym, *args, &block
      @_contain_component_parent.send sym, *args, &block
    end
    
    def initialize parent, component_module
      @_contain_component_parent = parent
      extend component_module
    end
  end
  
end
