require "#{File.dirname(__FILE__)}/../spec_helper"

describe "example" do

  describe "hostname実行" do
    describe command("hostname") do
      it { return_exit_status 0 }
    end
  end
end
