
require 'contain'


describe Contain::Component do
  
  subject { Contain::Component.new parent, mod }
  let(:parent) { Object.new }
  let(:mod) { module Mod; def foo(*args) end end; Mod }
  
  let(:args) { [1,2,3,kw:5,kw2:6] }
  let(:proc_arg) { Proc.new{nil} }
  
  it "uses the module's method when the method is defined" do
    subject.method(:foo).owner.should eq mod
    
    subject.should_receive(:foo)
           .with *args, &proc_arg
    subject.foo  *args, &proc_arg
  end
  
  it "forwards to the parent when the method is missing" do
    ->{subject.method(:bar)}.should raise_error
    
    parent.should_receive(:bar)
          .with  *args, &proc_arg
    subject.bar  *args, &proc_arg
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
