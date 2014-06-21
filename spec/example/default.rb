require "#{File.dirname(__FILE__)}/../spec_helper"

describe "example" do

  describe "hostname実行" do
    describe command("expect -c \'set timeout 5; spawn sudo /usr/sbin/tcpdump -i eth2 -n vrrp; expect eof\' | grep 'vrid 999'") do
      it { return_exit_status 0 }
    end
  end
end
