
module Contain
  
  # @api private
  module BaseGuardMethods
    def warn_about obj
      warn "WARNING\n"\
           "#{obj} is intended only for use in a Contain::Part.\n"\
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
        ::Contain::Guard.warn_about self unless obj.is_a? ::Contain::Part
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
