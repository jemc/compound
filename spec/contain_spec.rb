
require 'contain'

require 'spec_helper'


describe Contain::Host do
  
  let(:subject)  { Object.new.extend Contain::Host }
  let(:contained) { subject.instance_variable_get :@_contain_host_parts }
  
  let(:mod_foo)  { module Foo; def foo(*args) 'foo' end end; Foo }
  let(:mod_bar)  { module Bar; def bar(*args) 'bar' end end; Bar }
  
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
