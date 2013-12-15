
module Contain
  
  module Host
    def contain mod
      @_contain_host_parts ||= []
      @_contain_host_parts.unshift ::Contain::Component.new self, mod
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
  
  
  class Component
    def method_missing sym, *args, &block
      @_contain_component_parent.send sym, *args, &block
    end
    
    def initialize parent, component_module
      @_contain_component_parent = parent
      extend component_module
    end
  end
  
  
  # @api private
  module BaseGuardMethods
    def warn_about obj
      warn "WARNING\n"\
           "#{obj} is intended only for use in a Contain::Component.\n"\
           "Please use Contain::Host#contain instead of #extend or #include.\n"\
           "\n"
    end
    
    def included mod
      guard mod
    end
  end
  
  
  module Guard
    extend BaseGuardMethods
    
    # @api private
    def self.guard mod
      mod.define_singleton_method :extended do |obj|
        ::Contain::Guard.warn_about self unless obj.is_a? ::Contain::Component
      end
      mod.define_singleton_method :included do |_|
        ::Contain::Guard.warn_about self
      end
    end
  end
  
  
  module GuardAgainst
    extend BaseGuardMethods
    
    # @api private
    def self.guard mod
      mod.define_singleton_method :contained do |_|
        ::Contain::GuardAgainst.warn_about self
      end
    end
  end
  
end
