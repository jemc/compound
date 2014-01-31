
module Compound
  
  # Include this module in a class to gain the ability to host Parts,
  # which each embody a module, appearing to an outside object as if
  # the modules themselves were mixed in, while maintaining separation
  # among the modules.  Refer to the README for more information
  module Host
    
    # Internalize a new Part embodying the given module
    def compound mod
      @_compound_parts ||= []
      uncompound mod
      @_compound_parts.unshift ::Compound::Part.new self, mod
      mod.compounded(self) if mod.respond_to? :compounded
      return mod
    end
    
    # Remove the Part associated with the given module
    def uncompound mod
      (@_compound_parts &&
      (@_compound_parts.reject! { |part| part.is_a? mod } ? mod : nil))
    end
    
    # Forward an undefined method if it is in one of the Parts
    def method_missing sym, *args, &block
      component = @_compound_parts && 
                  @_compound_parts.detect { |obj| obj.respond_to? sym }
      component ? (component.send sym, *args, &block) : super
    end
    
    # Pretend to also respond_to methods in the Parts as well as the Host
    def respond_to? sym
      super || !!(@_compound_parts && 
                  @_compound_parts.detect { |obj| obj.respond_to? sym })
    end
    
    # Return the Method object associated with the symbol, 
    # even if it is in one of the Parts and not the Host
    def method sym
      return super if methods.include? sym
      component = @_compound_parts && 
                  @_compound_parts.detect { |obj| obj.respond_to? sym }
      component ? component.method(sym) :
        raise(NameError, "undefined method `#{sym}' for object `#{self}'")
    end
    
  private
    
    def send_to_parts sym, *args, &block
      results = @_compound_parts.map do |part|
        if part.respond_to? sym, true
          [part.instance_variable_get(:@_compound_component_module),
           part.send(sym, *args, &block)]
        end
      end.compact
      Hash[results]
    end
    
  end
  
end
