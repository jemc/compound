
require 'contain'


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
