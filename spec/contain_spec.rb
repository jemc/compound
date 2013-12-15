
require 'contain'

require 'spec_helper'


describe Contain::Container do
  
  let(:subject)  { Object.new.extend Contain::Container }
  
  let(:mod_foo)  { module Foo; def foo(*args) 'foo' end end; Foo }
  let(:mod_bar)  { module Bar; def bar(*args) 'bar' end end; Bar }
  
  let!(:comp_foo) { subject.contain mod_foo
                    contained.detect{|x| x.respond_to? :foo } }
  let!(:comp_bar) { subject.contain mod_bar
                    contained.detect{|x| x.respond_to? :bar } }
  
  let(:contained) { subject.instance_variable_get :@_container_parts }
  
  let(:args) { [1,2,3,kw:5,kw2:6] }
  let(:proc_arg) { Proc.new{nil} }
  
  it "forwards methods to the contained objects which respond_to them" do
    comp_foo.should_receive(:foo).with *args, &proc_arg
    comp_bar.should_receive(:bar).with *args.reverse, &proc_arg
    
    subject.foo *args, &proc_arg
    subject.bar *args.reverse, &proc_arg
  end
  
  it "gives first priority to methods actually defined in the container" do
    subject.singleton_class.send(:define_method, :container_method) {}
    
    comp_foo.should_not_receive(:foo)
    subject.should_receive(:foo).with *args, &proc_arg
    subject.foo *args, &proc_arg
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