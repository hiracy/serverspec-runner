require 'serverspec'
require 'pathname'
require 'net/ssh'
require 'yaml'
require 'csv'
require 'serverspec-runner/util/hash'

include Serverspec::Helper::DetectOS

ssh_options = YAML.load_file(ENV['ssh_options'])
csv_path = ENV['result_csv']
explains = []
results = []

RSpec.configure do |c|

  c.path = ENV['EXEC_PATH']

  run_path = c.files_to_run[0].split('/')
  if run_path[run_path.length - 3] == 'spec'
    role_name = run_path[run_path.length - 2]
  else
    role_name = run_path[run_path.length - 3] + "-" + run_path[run_path.length - 2]
  end

  if ENV['ASK_SUDO_PASSWORD']
    require 'highline/import'
    c.sudo_password = ask("Enter sudo password: ") { |q| q.echo = false }
  else
    c.sudo_password = ENV['SUDO_PASSWORD']
  end

  set_property (YAML.load_file(ENV['platforms_tmp']))[ENV['TARGET_HOST'].to_sym]

  if ENV['TARGET_SSH_HOST'] =~ /localhost|127\.0\.0\.1/
    include Serverspec::Helper::Exec
    c.os = backend(Serverspec::Commands::Base).check_os
  else
    include SpecInfra::Helper::Ssh

    c.host = ENV['TARGET_SSH_HOST']
    options = Net::SSH::Config.for(c.host, files=["~/.ssh/config"])
    user    = options[:user] || ssh_options[:user] || Etc.getlogin

    c.ssh   = Net::SSH.start(c.host, user, options.merge(ssh_options))
    c.os    = backend.check_os
  end

  c.before(:suite) do
    entity_host = (((ENV['TARGET_HOST'] != ENV['TARGET_SSH_HOST']) && (ENV['TARGET_SSH_HOST'] != nil)) ? "(#{ENV['TARGET_SSH_HOST']})" : "")
    puts "\e[33m"
    puts "### start [#{role_name}@#{ENV['TARGET_HOST']}] #{entity_host} serverspec... ###"
    print "\e[m"

    explains << "#{role_name}@#{ENV['TARGET_HOST']}#{entity_host}"
    results << ""
  end

  c.after(:each) do
    if ENV['explain'] == 'long'
      explains << "  " + self.example.metadata[:full_description] + (RSpec::Matchers.generated_description || '')
    else

      second_depth = self.example.metadata.depth - 3
      h = self.example.metadata

      second_depth.times do |i|
        h = h[:example_group]
      end

      second_desc = h[:description]
      first_desc = h[:example_group][:description]

      explains << "  " + first_desc + " " + second_desc
    end
    results << (self.example.exception ? 'NG' : 'OK')
  end

  c.after(:suite) do
    CSV.open(csv_path, 'a') do |writer|
      explains.each_with_index do |v, i|
        writer << [v, results[i]]
      end
    end
  end
end
