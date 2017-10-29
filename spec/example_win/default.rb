require 'spec_helper_win'

describe command('hostname') do
  its(:stdout) { should match /HOSTNAME/ }
end

describe file('c:/windows') do
  it { should be_directory }
end

describe command('tzutil /g') do
  its(:stdout) { should match /Tokyo Standard Time/ }
end

describe windows_feature('notepad') do
  it{ should be_installed }
end

