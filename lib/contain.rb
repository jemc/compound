
module Contain
  
  module Container
    def method_missing sym, *args, &block
      component = @_container_parts && 
                  @_container_parts.detect { |obj| obj.respond_to? sym }
      component ? (component.send sym, *args, &block) : super
    end
    
    def contain mod
      @_container_parts ||= []
      @_container_parts.unshift ::Contain::Component.new self, mod
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
  
  
  module Guard
    def self.warn_about obj
      warn "WARNING\n"\
           "#{obj} is intended only for use in a Contain::Component.\n"\
           "Please use Contain::Container#contain instead of #extend or #include.\n"\
           "\n"
    end
    
    # @api private
    def self.guard mod
      mod.send :define_method, :extended do |obj|
        ::Contain::Guard.warn_about self unless obj.is_a? ::Contain::Component
      end
      mod.send :define_method, :included do |_|
        ::Contain::Guard.warn_about self
      end
    end
    
    def self.included mod
      guard mod.singleton_class
    end
  end
  
end
