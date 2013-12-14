
module Contain
  
  module Host
    def method_missing sym, *args, &block
      component = @_contain_host_parts && 
                  @_contain_host_parts.detect { |obj| obj.respond_to? sym }
      component ? (component.send sym, *args, &block) : super
    end
    
    def contain mod
      @_contain_host_parts ||= []
      @_contain_host_parts.unshift ::Contain::Component.new self, mod
    end
  end
  
  
  class Component
    def method_missing sym, *args, &block
      @_contain_component_parent.send sym, *args, &block
    end
    
    def initialize parent, component_module
      @_contain_component_parent = parent
      extend component_module
    end
  end
  
end
