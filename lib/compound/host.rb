
module Compound
  
  module Hosting
    def compound mod
      @_compound_host_parts ||= []
      @_compound_host_parts.unshift ::Compound::Part.new self, mod
      mod.compounded(self) if mod.respond_to? :compounded
    end
    
    def method_missing sym, *args, &block
      component = @_compound_host_parts && 
                  @_compound_host_parts.detect { |obj| obj.respond_to? sym }
      component ? (component.send sym, *args, &block) : super
    end
    
    def respond_to? sym
      super || !!(@_compound_host_parts && 
                  @_compound_host_parts.detect { |obj| obj.respond_to? sym })
    end
    
    def method sym
      return super if methods.include? sym
      component = @_compound_host_parts && 
                  @_compound_host_parts.detect { |obj| obj.respond_to? sym }
      component ? component.method(sym) :
        raise(NameError, "undefined method `#{sym}' for object `#{self}'")
    end
  end
  
  class Host
    include Hosting
  end
  
end
