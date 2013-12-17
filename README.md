
Compound provides a mechanism for mixing together modules into an object 
while maintaining some degree of separation to help avoid namespace collisions.

# Object Creation

An instance of a class that includes the `Compound::Host` module gains 
the ability to host one or more `Compound::Part`s within it.

``` ruby
  class ManyFacedObject
    include Compound::Host
  end
```

A `Part` is constructed within the `Host` when `#compound` is called.
The new `Part` is an object `#extend`ed by the module passed to `#compound`.
Any number of modules can be `#compound`ed into the `Host`.

``` ruby
  module Anger;  end
  module Sorrow; end
  module Joy;    end
  
  host = ManyFacedObject.new
  host.compound Anger
  host.compound Sorrow
  host.compound Joy
```

# Method Forwarding

If a method is called on the `Host` which is not defined by the `Host`, but
is defined by one of the `#compound`ed modules, the method and arguments 
will be forwarded to the internal `Part` object associated with that module.
If more than one module defines the method, it will be forwarded to the one
which was most recently `#compound`ed.

``` ruby
  host.countenance #=> raises NoMethodError
  
  module Anger
    def countenance
      :grimace
    end
  end
  
  host.countenance #=> :grimace  # host can now forward to the new Anger method
  
  module Joy
    def countenance
      :grin
    end
  end
  
  host.countenance #=> :grin  # Joy shadows Anger because Joy was compounded later
  
  module Sorrow
    def countenance
      :frown
    end
  end
  
  host.countenance #=> :grin  # Joy also shadows Sorrow because Joy was compounded later
```

`Part` objects will also forward unknown methods back to the `Host`, 
allowing methods of a `#compound`ed module to call public methods 
of the other `#compound`ed modules or of the `Host` itself "natively" 
(without specifying an explicit receiver).

``` ruby
  module Anger
    def shout(msg)
      msg.upcase + '!'
    end
  end
  
  module Joy
    def exclaim
      shout 'hooray'
    end
  end
  
  host.exclaim #=> 'HOORAY!'
```

# Privacy

Due to this forwarding of methods, the `Host` appears to an outside object
as if all of the `#compound`ed modules were mixed into it with `#extend`.
However, the modules' private parts remain partitioned from one another.
For example, private methods and instance variables are not shared among them.

``` ruby
  module Sorrow
    private
    def weep
      '...'
    end
  end
  
  module Joy
    def overcome_by_beauty
      weep #=> raises NoMethodError
    end
  end
  
  host.overcome_by_beauty #=> call to :weep raises NoMethodError
```
``` ruby
  module Joy
    attr_accessor :value
  end
  
  module Anger
    def internalize(value)
      @value = value
    end
    
    def recall
      @value
    end
  end
  
  host.value          #=> nil  # @value retrieved from Joy
  host.internalize 88 #=> 88   # @value stored in Anger
  host.recall         #=> 88   # @value retrieved from Anger
  host.value          #=> nil  # @value retrieved from Joy
  host.value = 999    #=> 999  # @value stored in Joy
  host.recall         #=> 88   # @value retrieved from Anger
```

This is the chief advantage to using `#compound` instead of `#extend`.
The modules need no longer worry about avoiding namespace collisions in
private behaviour.  This leads to fewer mixing compatibility issues among 
modules that may not necessarily be versioned in relation to one another.
