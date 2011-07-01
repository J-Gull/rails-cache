require "spec_helper"

module Cash
  describe Local do
    it "should have method missing as a private method" do
      Local.private_instance_methods.should include("method_missing")
    end
  end
end