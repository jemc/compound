
module Compound
  
  # A object that includes the {Host} module gains the ability to host
  # one or more {Part}s within it.
  #
  # A {Part} is constructed within the {Host} when {#compound} is called.
  # The new {Part} is an object +extend+ed by the module passed to {#compound}.
  # Any number of modules can be {#compound}ed into the {Host}.
  #
  # If a method is called on the {Host} which is not defined by the {Host}, but
  # is defined by one of the {#compound}ed modules, the method and arguments 
  # will be forwarded to the internal {Part} object associated with that module.
  #
  module Host
    def compound mod
      @_compound_parts ||= []
      @_compound_parts.unshift ::Compound::Part.new self, mod
      mod.compounded(self) if mod.respond_to? :compounded
    end
    
    def method_missing sym, *args, &block
      component = @_compound_parts && 
                  @_compound_parts.detect { |obj| obj.respond_to? sym }
      component ? (component.send sym, *args, &block) : super
    end
    
    def respond_to? sym
      super || !!(@_compound_parts && 
                  @_compound_parts.detect { |obj| obj.respond_to? sym })
    end
    
    def method sym
      return super if methods.include? sym
      component = @_compound_parts && 
                  @_compound_parts.detect { |obj| obj.respond_to? sym }
      component ? component.method(sym) :
        raise(NameError, "undefined method `#{sym}' for object `#{self}'")
    end
  end
  
end
