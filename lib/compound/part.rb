
module Compound
  
  class Part
    def method_missing sym, *args, &block
      @_compound_component_parent.send sym, *args, &block
    end
    
    def initialize parent, mod
      @_compound_component_parent = parent
      @_compound_component_module = mod
      extend mod
      compounded(parent) if mod.instance_methods.include? :compounded
    end
  end
  
end
