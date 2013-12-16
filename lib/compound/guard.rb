
module Compound
  
  # @api private
  module BaseGuardMethods
    def warn_about obj
      warn "WARNING\n"\
           "#{obj} is intended only for use in a Compound::Part.\n"\
           "Please use Compound::Host#compound instead of #extend or #include.\n"\
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
        ::Compound::Guard.warn_about self unless obj.is_a? ::Compound::Part
      end
      mod.define_singleton_method :included do |_|
        ::Compound::Guard.warn_about self
      end
    end
  end
  
  
  module GuardAgainst
    extend BaseGuardMethods
    
    # @api private
    def self.guard mod
      mod.define_singleton_method :compounded do |_|
        ::Compound::GuardAgainst.warn_about self
      end
    end
  end
  
end
