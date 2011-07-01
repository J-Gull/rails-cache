require "spec_helper"

module Cash
  describe LocalBuffer do
    it "should have method missing as a private method" do
      LocalBuffer.private_instance_methods.should include("method_missing")
    end
  end
end