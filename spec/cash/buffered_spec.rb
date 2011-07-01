require "spec_helper"

module Cash
  describe Buffered do
    it "should have method missing as a private method" do
      Buffered.private_instance_methods.should include("method_missing")
    end
  end
end