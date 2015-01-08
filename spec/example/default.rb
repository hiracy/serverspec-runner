require 'spec_helper'

describe user('root') do
  it { should exist }
  it { should have_uid 0 }
  it { should have_home_directory '/root' }
end

describe group('root') do
  it { should have_gid 0 }
end

describe 'Filesystem' do
  describe file('/') do
    it { should be_mounted }
  end
end

describe host('www.google.com') do
  it { should be_resolvable }
  it { should be_reachable }
end

describe command('dmesg | grep "FAIL\|Fail\|fail\|ERROR\|Error\|error"') do
  its(:exit_status){ should_not eq 0 }
end
