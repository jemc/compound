
Compound provides a mechanism for mixing together modules into an object 
while maintaining some degree of separation to help avoid namespace collisions.

# Compounding

An instance of a class that includes the `Compound::Host` module gains 
the ability to host one or more `Compound::Part`s within it.

``` ruby
  require 'compound'
  
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


# Uncompounding

As luck would have it, a module can be `#uncompound`ed just as simply 
as it was `#compound`ed.

``` ruby
  host.uncompound Anger
  host.uncompound Sorrow
  #=> only Joy remains!
```


# Defining Modules for Compounding

Some points to keep in mind when defining a module specifically for compounding:

- Public methods are 'shared' and should be considered the 'interface' to 
  your module; this interface should remain well-documented and versioned.

- Private methods are defined only in support of the module,
  and because they are not shared, they are free to change and rearrange
  without worry of namespace collisions with methods of the extended objects
  or about other object methods depending on the use of them.

- Instance variables are also not shared, neither among modules nor between
  compounded module and host.  However, when accessors are defined for them
  the accessors are part of the public interface along with other 
  public methods, and should be treated as such.

Because the mechanism of compounding uses a module somewhat differently 
from how it is used in the traditional inclusion/extension mechanism, 
one might want to ensure that the module is used correctly.
If `Compound::Guard` is `include`d in a module, it will `warn` the user 
if that module is `include`d or `extend`ed instead of `compound`ed. 

``` ruby
  module CompoundOnly
    include Compound::Guard
  end
  
  module OtherModule
    include CompoundOnly          #=> warns the user
  end
  
  Object.new.extend CompoundOnly  #=> warns the user
  
  host.compound CompoundOnly      #=> intended usage, no warning
```

Inversely, one might wish to ensure that a module intended to be used
traditionally is not used in compounding.
If `Compound::GuardAgainst` is `include`d in a module, 
it will `warn` the user if that module is `compound`ed. 

``` ruby
  module TraditionalModule
    include Compound::GuardAgainst
  end
  
  module OtherModule
    include TraditionalModule          #=> intended usage, no warning
  end
  
  Object.new.extend TraditionalModule  #=> intended usage, no warning
  
  host.compound TraditionalModule      #=> warns the user
```


# Initialization of Modules

Sometimes, a module might want to know that it has been compounded so that it
can initialize its internal state.  Traditional module composition will call
the `extended` or `self.included` methods if they are defined by the module.
However, modules intended for compounding should define a `compounded` method
instead, to be called upon creation of the `Host`'s internal `Part` object.
The `compounded` method should accept a single argument: the `Host` object.

``` ruby
  module Paint
    def compounded(host)
      @color = :royal_blue
    end
    attr_accessor :color
  end
  
  host.compound Paint
  host.color          #=> :royal_blue
```

The `Host` will also pass itself to the `self.compounded` method on the module
passed to `compound` if the method is defined.

``` ruby
  module Paint
    def self.compounded(host)
      @latest = host
    end
    attr_accessor :latest
  end
  
  Paint.latest          #=> nil
  host.compound Paint
  Paint.latest == host  #=> true
```

# Calling a Method on Each Part

Compound::Host has a private method for calling `send` on each of its `Part`
objects.  Because it uses `send`, it can access both public and private methods
of each `Part`.  The return values of the methods are collected into a hash
with the compounded modules as the keys.

``` ruby
  module RedPaint
    private
    def load_brush(intensity)
      '0x%02x0000' % intensity
    end
  end
  
  module BluePaint
    private
    def load_brush(intensity)
      '0x0000%02x' % intensity
    end
  end
  
  host.define_singleton_method(:load_brushes) { send_to_all :load_brush, 0xff }
  
  host.load_brushes #=> { RedPaint=>'#ff0000', BluePaint=>'#0000ff' }
```
