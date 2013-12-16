
require 'compound'

require 'spec_helper'


describe Compound::Part do
  
  subject { Compound::Part.new parent, mod }
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
