
require 'spec_helper'


describe Compound::Guard do
  
  let(:guarded) { module Guarded; include Compound::Guard end; Guarded }
  let(:obj) { Object.new }
  let(:mod) { Module.new }
  
  it "warns when you try to extend with a guarded object" do
    subject.should_receive :warn_about
    obj.extend guarded
  end
  
  it "warns when you try to include with a guarded object" do
    subject.should_receive :warn_about
    mod.send :include, guarded
  end
  
  it "can warn about any object" do
    str = obj.to_s
    subject.should_receive(:warn).with(/#{obj}/)
    subject.warn_about str
  end

end


describe Compound::GuardAgainst do
  
  let(:guarded) { module Guarded; include Compound::GuardAgainst end; Guarded }
  let(:obj) { Object.new.extend Compound::Host }
  let(:mod) { Module.new }
  
  it "warns when you try to compound with a guarded object" do
    subject.should_receive :warn_about
    obj.compound guarded
  end
  
  it "can warn about any object" do
    str = obj.to_s
    subject.should_receive(:warn).with(/#{obj}/)
    subject.warn_about str
  end

end
