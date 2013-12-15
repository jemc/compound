
require 'contain'

require 'spec_helper'


describe Contain::Host do
  
  let(:subject)  { Object.new.extend Contain::Host }
  let(:contained) { subject.instance_variable_get :@_contain_host_parts }
  
  let(:mod_foo)  { Module.new.tap{|m| m.class_eval{ def foo(*args) 'foo' end }}}
  let(:mod_bar)  { Module.new.tap{|m| m.class_eval{ def bar(*args) 'bar' end }}}
  
  let(:comp_foo) { subject.contain mod_foo
                    contained.detect{|x| x.respond_to? :foo } }
  let(:comp_bar) { subject.contain mod_bar
                    contained.detect{|x| x.respond_to? :bar } }
  
  let(:args) { [1,2,3,kw:5,kw2:6] }
  let(:proc_arg) { Proc.new{nil} }
  
  it "can contain modules" do
    comp_foo.singleton_class.ancestors.should include mod_foo
    comp_bar.singleton_class.ancestors.should include mod_bar
    
    comp_foo.should be_a Contain::Component
    comp_bar.should be_a Contain::Component
    
    contained.should match_array [comp_foo, comp_bar]
  end
  
  it "calls the .contained method of the module if it is defined" do
    mod_foo.should_receive(:contained).with(subject)
    comp_foo
  end
  
  it "forwards methods to the contained objects which respond_to them" do
    comp_foo.should_receive(:foo).with *args, &proc_arg
    comp_bar.should_receive(:bar).with *args.reverse, &proc_arg
    
    subject.foo *args, &proc_arg
    subject.bar *args.reverse, &proc_arg
  end
  
  it "gives first priority to methods actually defined in the container" do
    subject.define_singleton_method(:foo) { |*args| 'container method'}
    
    comp_foo.should_not_receive(:foo)
    subject.foo(*args, &proc_arg).should eq 'container method'
  end
  
  it "pretends to respond_to methods which it does not actually define" do
    comp_foo
    comp_bar
    subject.define_singleton_method(:container_method) { |*args| }
    
    subject.methods.should_not include :foo
    subject.methods.should_not include :bar
    subject.methods.should     include :container_method
    subject.methods.should_not include :undefined
    
    subject.should     respond_to :foo
    subject.should     respond_to :bar
    subject.should     respond_to :container_method
    subject.should_not respond_to :undefined
  end
  
  it "can retrieve the method object for its forwarded methods" do
    comp_foo
    comp_bar
    subject.define_singleton_method(:container_method) { |*args| }
    
    subject.method(:foo)             .owner.should eq mod_foo
    subject.method(:bar)             .owner.should eq mod_bar
    subject.method(:container_method).owner.should eq subject.singleton_class
    
    ->{subject.method(:undefined)}.should raise_error NameError, /undefined method/
  end
  
  it "uses late binding and search to find forwardable methods" do
    comp_foo
    
    subject.foo.should eq 'foo'
    ->{subject.other}.should raise_error NoMethodError
    
    mod_foo.class_eval do
      remove_method :foo
      def other(*args) 'other' end
    end
    
    ->{subject.foo}.should raise_error NoMethodError
    subject.other.should eq 'other'
  end
  
  it "forwards to the more recently contained object when methods conflict" do
    comp_foo
    comp_bar
    mod_bar.class_eval { def foo(*args) 'bar_foo' end }
    
    subject.foo.should eq 'bar_foo'
  end
  
  it "does not know about private methods of contained objects" do
    comp_foo
    mod_foo.class_eval { private; def private_method; end }
    
    ->{subject.private_method}.should raise_error NoMethodError
  end
  
  it "allows contained objects implicit access to eachother's public methods" do
    comp_foo
    comp_bar
    mod_bar.class_eval { def other(*args) foo end }
    
    subject.other.should eq 'foo'
  end
  
  it "does not intersend the private methods of contained objects" do
    comp_foo
    comp_bar
    mod_foo.class_eval { def foo(*args) private_foo end }
    mod_bar.class_eval { def bar(*args) private_foo end }
    mod_foo.class_eval { private; def private_foo(*args) 'priv_foo' end }
    
    subject.foo.should eq 'priv_foo'
    ->{subject.bar}.should raise_error NoMethodError
  end
  
  it "allows contained objects to all have their own version of a private method" do
    comp_foo
    comp_bar
    mod_foo.class_eval { def foo(*args) private_meth end }
    mod_bar.class_eval { def bar(*args) private_meth end }
    mod_foo.class_eval { private; def private_meth(*args) 'priv_foo' end }
    mod_bar.class_eval { private; def private_meth(*args) 'priv_bar' end }
    
    subject.foo.should eq 'priv_foo'
    subject.bar.should eq 'priv_bar'
  end
  
  it "does not bridge ivars between contained objects" do
    comp_foo
    comp_bar
    
    comp_foo.instance_variable_get(:@ivar).should eq nil
    comp_bar.instance_variable_get(:@ivar).should eq nil
    
    comp_foo.instance_variable_set(:@ivar, 55)
    comp_foo.instance_variable_get(:@ivar).should eq 55
    comp_bar.instance_variable_get(:@ivar).should eq nil
    
    comp_bar.instance_variable_set(:@ivar, 999)
    comp_foo.instance_variable_get(:@ivar).should eq 55
    comp_bar.instance_variable_get(:@ivar).should eq 999
  end
  
end


describe Contain::Component do
  
  subject { Contain::Component.new parent, mod }
  let(:parent) { Object.new }
  let(:mod) { module Mod; def foo(*args) end end; Mod }
  
  let(:args) { [1,2,3,kw:5,kw2:6] }
  let(:proc_arg) { Proc.new{nil} }
  
  it "uses the module's method when the method is defined" do
    subject.method(:foo).owner.should eq mod
    
    subject.should_receive(:foo).with *args, &proc_arg
    subject.foo *args, &proc_arg
  end
  
  it "forwards to the parent when the method is missing" do
    ->{subject.method(:bar)}.should raise_error
    
    parent.should_receive(:bar).with *args, &proc_arg
    subject.bar *args, &proc_arg
  end
  
end


describe Contain::Guard do
  
  let(:guarded) { module Guarded; include Contain::Guard end; Guarded }
  let(:obj) { Object.new }
  let(:mod) { Module.new }
  
  it "warns when you try to extend with a guarded object" do
    subject.should_receive :warn_about
    obj.extend guarded
  end
  
  it "warns when you try to include with a guarded object" do
    subject.should_receive :warn_about
    mod.include guarded
  end
  
  it "can warn about any object" do
    str = obj.to_s
    subject.should_receive(:warn).with(/#{obj}/)
    subject.warn_about str
  end

end
