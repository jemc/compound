
module Compound
  
  # Include this module in a class to gain the ability to host Parts,
  # which each embody a module, appearing to an outside object as if
  # the modules themselves were mixed in, while maintaining separation
  # among the modules.  Refer to the README for more information
  module Host
    
    # Internalize a new Part embodying the given module
    def compound mod
      first_time_array = nil
      @_compound_parts ||= (first_time_array=[])
      
      # Pretend that the compounded modules are in the inheritance tree
      singleton_class.send :define_singleton_method, :ancestors do
        super() + first_time_array.map { |part|
          part.instance_variable_get(:@_compound_component_module)
        }
      end if first_time_array
      
      uncompound mod
      @_compound_parts.unshift ::Compound::Part.new self, mod
      mod.compounded(self) if mod.respond_to? :compounded
      return mod
    end
    
    # Remove the Part associated with the given module
    def uncompound mod
      (@_compound_parts &&
      (@_compound_parts.reject! { |part|
        part.instance_variable_get(:@_compound_component_module) == mod
      } ? mod : nil))
    end
    
    # Forward an undefined method if it is in one of the Parts
    def method_missing sym, *args, &block
      component = @_compound_parts && 
                  @_compound_parts.detect { |obj| obj.respond_to? sym }
      component ? (component.send sym, *args, &block) : super
    end
    
    # Pretend to also respond_to methods in the Parts as well as the Host
    def respond_to? sym, *rest
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
    
    # Pretend that the compounded modules are in the inheritance tree
    def kind_of? mod
      super or !!(@_compound_parts && @_compound_parts.detect { |part|
        part.instance_variable_get(:@_compound_component_module) == mod
      })
    end
    
    # Pretend that the compounded modules are in the inheritance tree
    def is_a? mod
      super or !!(@_compound_parts && @_compound_parts.detect { |part|
        part.instance_variable_get(:@_compound_component_module) == mod
      })
    end
    
  private
    
    # A private method to enumerate over all of the compound parts,
    #   in order of compounding, starting with the most recently compounded
    def each_part &block
      (@_compound_parts || []).each &block
    end
    
    # A private method to enumerate over all of the compound parts,
    #   in order of compounding, starting with the most recently compounded,
    #   returning both the associated module and the part for each
    def each_pair &block
      (@_compound_parts || []).map { |part|
        [part.instance_variable_get(:@_compound_component_module), part]
      }.each &block
    end
    
    # A private method to call send on each Compound::Part that defines the
    #   given method, whether publically or privately.  The return values are
    #   collected into a hash with the compounded modules as the keys.
    def send_to_parts sym, *args, &block
      (@_compound_parts || []).each_with_object({}) do |part, hash|
        hash[part.instance_variable_get(:@_compound_component_module)] = \
          part.send sym, *args, &block \
            if part.respond_to? sym, true
      end
    end
    
    # A private method to call send on the Compound::Part
    #   associated with the given module.
    def send_to_part mod, sym, *args, &block
      (@_compound_parts || []).each do |part|
        if part.instance_variable_get(:@_compound_component_module) == mod
          return part.send sym, *args, &block
        end
      end
      raise ArgumentError, "No Part corresponding to #{mod}"
    end
    
  end
  
end
