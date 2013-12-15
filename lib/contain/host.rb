
module Contain
  
  module Hosting
    def contain mod
      @_contain_host_parts ||= []
      @_contain_host_parts.unshift ::Contain::Part.new self, mod
      mod.contained(self) if mod.respond_to? :contained
    end
    
    def method_missing sym, *args, &block
      component = @_contain_host_parts && 
                  @_contain_host_parts.detect { |obj| obj.respond_to? sym }
      component ? (component.send sym, *args, &block) : super
    end
    
    def respond_to? sym
      super || !!(@_contain_host_parts && 
                  @_contain_host_parts.detect { |obj| obj.respond_to? sym })
    end
    
    def method sym
      return super if methods.include? sym
      component = @_contain_host_parts && 
                  @_contain_host_parts.detect { |obj| obj.respond_to? sym }
      component ? component.method(sym) :
        raise(NameError, "undefined method `#{sym}' for object `#{self}'")
    end
  end
  
  class Host
    include Hosting
  end
  
end
