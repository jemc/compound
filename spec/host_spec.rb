
require 'compound'

require 'spec_helper'


describe Compound::Host do
  let(:subject)  { Object.new.extend Compound::Host }
  
  let(:compounded) { subject.instance_eval { @_compound_parts } }
  
  let(:mod_foo)  { Module.new.tap{|m| m.class_eval{ def foo(*args) 'foo' end }}}
  let(:mod_bar)  { Module.new.tap{|m| m.class_eval{ def bar(*args) 'bar' end }}}
  let(:mod_baz)  { Module.new.tap{|m| m.class_eval{ def baz(*args) 'baz' end }}}
  
  let(:part_foo) { subject.compound mod_foo
                    compounded.detect{|x| x.respond_to? :foo } }
  let(:part_bar) { subject.compound mod_bar
                    compounded.detect{|x| x.respond_to? :bar } }
  let(:part_baz) { subject.compound mod_baz
                    compounded.detect{|x| x.respond_to? :baz } }
  
  let(:args) { [1,2,3,kw:5,kw2:6] }
  let(:proc_arg) { Proc.new{nil} }
  
  it "can compound modules" do
    part_foo.singleton_class.ancestors.should include mod_foo
    part_bar.singleton_class.ancestors.should include mod_bar
    
    part_foo.should be_a Compound::Part
    part_bar.should be_a Compound::Part
    
    compounded.should match_array [part_foo, part_bar]
  end
  
  it "returns the module given when it gets compounded" do
    retval = subject.compound mod_foo
    retval.should eq mod_foo
  end
  
  it "compounds at most one part for each given module" do
    subject.compound mod_foo
    subject.compound mod_foo
    subject.compound mod_bar
    subject.compound mod_foo
    subject.compound mod_bar
    subject.compound mod_bar
    subject.compound mod_foo
    
    compounded.should match_array [part_foo, part_bar]
  end
  
  it "can uncompound a module" do
    subject.compound mod_foo
    compounded.should match_array [part_foo]
    subject.uncompound mod_foo
    compounded.should match_array []
  end
  
  it "returns the module given when uncompound successfully removes a part" do
    subject.compound mod_foo
    retval = subject.uncompound mod_foo
    retval.should eq mod_foo
  end
  
  it "returns nil when uncompound can't find a matching part to remove" do
    retval = subject.uncompound mod_foo
    retval.should eq nil
    
    subject.compound mod_bar
    retval = subject.uncompound mod_foo
    retval.should eq nil
  end
  
  it "only recognizes the compounded module itself when uncompounding" do
    mod_bar.send :include, mod_foo
    
    retval = subject.uncompound mod_foo
    retval.should eq nil
    
    subject.compound mod_bar
    retval = subject.uncompound mod_foo
    retval.should eq nil
  end
  
  it "calls the .compounded method of the module if it is defined" do
    mod_foo.should_receive(:compounded).with(subject)
    part_foo
  end
  
  it "forwards methods to the compounded objects which respond_to them" do
    part_foo.should_receive(:foo).with *args, &proc_arg
    part_bar.should_receive(:bar).with *args.reverse, &proc_arg
    
    subject.foo *args, &proc_arg
    subject.bar *args.reverse, &proc_arg
  end
  
  it "gives first priority to methods actually defined in the compounder" do
    subject.define_singleton_method(:foo) { |*args| 'compounder method'}
    
    part_foo.should_not_receive(:foo)
    subject.foo(*args, &proc_arg).should eq 'compounder method'
  end
  
  it "pretends to respond_to methods which it does not actually define" do
    part_foo
    part_bar
    subject.define_singleton_method(:compounder_method) { |*args| }
    
    subject.methods.should_not include :foo
    subject.methods.should_not include :bar
    subject.methods.should     include :compounder_method
    subject.methods.should_not include :undefined
    
    subject.should     respond_to :foo
    subject.should     respond_to :bar
    subject.should     respond_to :compounder_method
    subject.should_not respond_to :undefined
  end
  
  it "can retrieve the method object for its forwarded methods" do
    part_foo
    part_bar
    subject.define_singleton_method(:compounder_method) { |*args| }
    
    subject.method(:foo)             .owner.should eq mod_foo
    subject.method(:bar)             .owner.should eq mod_bar
    subject.method(:compounder_method).owner.should eq subject.singleton_class
    
    ->{subject.method(:undefined)}.should raise_error NameError, /undefined method/
  end
  
  it "uses late binding and search to find forwardable methods" do
    part_foo
    
    subject.foo.should eq 'foo'
    ->{subject.other}.should raise_error NoMethodError
    
    mod_foo.class_eval do
      remove_method :foo
      def other(*args) 'other' end
    end
    
    ->{subject.foo}.should raise_error NoMethodError
    subject.other.should eq 'other'
  end
  
  it "forwards to the more recently compounded module when methods conflict" do
    part_foo
    part_bar
    mod_bar.class_eval { def foo(*args) 'bar_foo' end }
    
    subject.foo.should eq 'bar_foo'
  end
  
  it "updates the 'order' of priority when a module is compounded again" do
    part_foo
    part_bar
    subject.compound mod_foo
    
    subject.foo.should eq 'foo'
  end
  
  it "does not know about private methods of compounded objects" do
    part_foo
    mod_foo.class_eval { private; def private_method; end }
    
    ->{subject.private_method}.should raise_error NoMethodError
  end
  
  it "allows compounded objects implicit access to eachother's public methods" do
    part_foo
    part_bar
    mod_bar.class_eval { def other(*args) foo end }
    
    subject.other.should eq 'foo'
  end
  
  it "does not intersend the private methods of compounded objects" do
    part_foo
    part_bar
    mod_foo.class_eval { def foo(*args) private_foo end }
    mod_bar.class_eval { def bar(*args) private_foo end }
    mod_foo.class_eval { private; def private_foo(*args) 'priv_foo' end }
    
    subject.foo.should eq 'priv_foo'
    ->{subject.bar}.should raise_error NoMethodError
  end
  
  it "allows compounded objects to all have their own version of a private method" do
    part_foo
    part_bar
    mod_foo.class_eval { def foo(*args) private_meth end }
    mod_bar.class_eval { def bar(*args) private_meth end }
    mod_foo.class_eval { private; def private_meth(*args) 'priv_foo' end }
    mod_bar.class_eval { private; def private_meth(*args) 'priv_bar' end }
    
    subject.foo.should eq 'priv_foo'
    subject.bar.should eq 'priv_bar'
  end
  
  it "does not bridge ivars between compounded objects" do
    part_foo
    part_bar
    
    part_foo.instance_variable_get(:@ivar).should eq nil
    part_bar.instance_variable_get(:@ivar).should eq nil
    
    part_foo.instance_variable_set(:@ivar, 55)
    part_foo.instance_variable_get(:@ivar).should eq 55
    part_bar.instance_variable_get(:@ivar).should eq nil
    
    part_bar.instance_variable_set(:@ivar, 999)
    part_foo.instance_variable_get(:@ivar).should eq 55
    part_bar.instance_variable_get(:@ivar).should eq 999
  end
  
  it "pretends that its compounded modules are in its inheritance tree" do
    part_foo
    part_bar
    
    subject.is_a?(mod_foo).should be
    subject.is_a?(mod_bar).should be
    
    subject.kind_of?(mod_foo).should be
    subject.kind_of?(mod_bar).should be
    
    subject.should be_a mod_foo
    subject.should be_a mod_bar
    
    subject.should be_kind_of mod_foo
    subject.should be_kind_of mod_bar
    
    subject.singleton_class.ancestors.should include mod_foo
    subject.singleton_class.ancestors.should include mod_bar
  end
  
  it "has a private method to enumerate over the parts in order" do
           part_baz; part_bar; part_foo
    ary = [part_foo, part_bar, part_baz] # reversed; most recent first
    
    subject.should_not respond_to :each_part
    subject.private_methods.should include :each_part
    
    # Enumerate without a block
    subject.instance_eval { each_part.to_a }.should eq ary
    
    # Enumerate with a block
    subject.instance_eval { a = []; each_part{ |x| a << x }; a }.should eq ary
  end
  
  it "has a private method to enumerate in order with modules as keys" do
           part_baz; part_bar; part_foo
    ary = [mod_foo, mod_bar, mod_baz].zip \
        [part_foo, part_bar, part_baz]
    
    subject.should_not respond_to :each_pair
    subject.private_methods.should include :each_pair
    
    # Enumerate without a block
    subject.instance_eval { each_pair.to_a }.should eq ary
    
    # Enumerate with a block
    subject.instance_eval { a = []; each_pair{ |x| a << x }; a }.should \
      eq ary
  end
  
  it "has a private method to call send on each part" do
    local_args = args
    part_foo; part_bar; part_baz
    mod_foo.class_eval { private; def priv(*args) expect *args; 33 end }
    mod_bar.class_eval {          def priv(*args) expect *args; 44 end }
    mod_baz.class_eval {} # Don't define the method here; it will be skipped
    subject.define_singleton_method(:call_each_private) \
      { send_to_parts :priv, *local_args }
    
    subject.should_not respond_to :send_to_parts
    subject.private_methods.should include :send_to_parts
    
    subject.should_receive(:expect).with(*local_args).twice
    
    subject.call_each_private.should eq({mod_foo=>33, mod_bar=>44})
  end
  
  it "has a private method to call send on a specific part" do
    local_args = args
    part_foo; part_bar; part_baz
    mod_foo.class_eval { private; def priv2(*args) expect *args; 33 end }
    mod_bar.class_eval { private; def priv2(*args) expect *args; 44 end }
    mod_baz.class_eval {} # Don't define the method here; it will be skipped
    subject.define_singleton_method(:call_private) \
      { |mod| send_to_part mod, :priv2, *local_args }
    
    subject.should_not respond_to :send_to_part
    subject.private_methods.should include :send_to_part
    
    subject.should_receive(:expect).with(*local_args).twice
    
    subject.call_private(mod_foo).should eq 33
    subject.call_private(mod_bar).should eq 44
    expect { subject.call_private(mod_baz) }.to raise_error
    expect { subject.call_private(Module.new) }.to raise_error ArgumentError
  end
  
end
