require 'rake'
require 'rspec/core/rake_task'
require 'yaml'
require 'csv'
require 'net/ssh'
require 'open-uri'
require 'serverspec-runner'

desc "Run serverspec to all scenario"
task :spec => 'spec:all'

namespace :spec do

  ENV['EXEC_PATH'] = '/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin'
  ENV['specpath'] = "#{File.dirname(__FILE__)}/spec" unless ENV['specpath']
  ENV['ssh_options'] = "#{File.dirname(__FILE__)}/ssh_options.yml" unless ENV['ssh_options']
  ssh_options = YAML.load_file(ENV['ssh_options'])
  ENV['result_csv'] = './_serverspec_result.csv' unless ENV['result_csv']
  csv_file = ENV['result_csv']
  CSV.open(csv_file, 'w') { |w| w << ['description', 'result'] }
  ENV['explain'] = "long" unless ENV['explain']
  ENV['tableformat'] = "aa" unless ENV['tableformat']
  ENV['scenario'] = "./scenario.yml" unless ENV['scenario']

  if !ENV['tmpdir']
    ENV['platforms_tmp'] = "./_platforms.yml"
    ENV['scenario_tmp'] = "./_scenario.yml"
  else
    ENV['platforms_tmp'] = "#{ENV['tmpdir']}/_platforms.yml"
    ENV['scenario_tmp'] = "#{ENV['tmpdir']}/_scenario.yml"
  end

  scenarios = nil
  platform = {}

  if ENV['scenario'] =~ /^http:\/\//
    open(ENV['scenario_tmp'], 'w') do |f|
      open(ENV['scenario']) do |data|
        f.write(data.read)
      end
    end

    ENV['scenario'] = ENV['scenario_tmp']
  end

  File.open(ENV['scenario'] || "#{File.dirname(__FILE__)}/scenario.yml") do |f|
    YAML.load_documents(f).each_with_index do |data, idx|
      if idx == 0
        scenarios = data
      else
        data.each do |k, v|
          platform[k.to_sym] = {}
          v.each do |kk, vv|
            platform[k.to_sym][kk.to_sym] = vv
          end
        end
      end
    end
  end

  if !scenarios
    print "\e[31m"
    puts "scenario.yml is empty."
    print "\e[m"
    exit 1
  end

  tasks = []

  scenarios.keys.each do |role|

    if scenarios[role].kind_of?(Array)

      scenarios[role].each do |host_alias|
        if platform.include?(host_alias.to_sym)
          ssh_host = platform[host_alias.to_sym][:host]
        else
          platform[host_alias.to_sym] = {}
          ssh_host = host_alias
        end
        tasks << "#{role}-#{host_alias}"
        platform[host_alias.to_sym] = ServerspecRunner::Detection.platform(ssh_host, ssh_options, platform[host_alias.to_sym])
      end
    elsif scenarios[role].kind_of?(Hash)

      scenarios[role].keys.each do |role_sub|

        scenarios[role][role_sub].each do |host_alias|
          if platform.include?(host_alias.to_sym)
            ssh_host = platform[host_alias.to_sym][:host]
          else
            platform[host_alias.to_sym] = {}
            ssh_host = host_alias
          end
          tasks << "#{role}-#{role_sub}-#{host_alias}"
          platform[host_alias.to_sym] = ServerspecRunner::Detection.platform(ssh_host, ssh_options, platform[host_alias.to_sym])
        end
      end
    end
  end

  task :csv_output do
    maxlen = 0
    CSV.foreach(csv_file) do |r|
      n =  r[0].each_char.map{|c| c.bytesize == 1 ? 1 : 2}.reduce(0, &:+)
      maxlen = n if n > maxlen
    end

    pad_spaces = 4

    if ENV['tableformat'] == 'mkd'
      spacer = "|:" + ("-" * maxlen) + "|:" + ("-" * "result".length) + ":|"
    else
      spacer = "+" + ("-" * (maxlen + "result".length + pad_spaces)) + "+"
    end

    puts spacer unless ENV['tableformat'] == 'mkd'
    is_header = true
    CSV.foreach(csv_file) do |r|
      n =  r[0].each_char.map{|c| c.bytesize == 1 ? 1 : 2}.reduce(0, &:+)
      pad_mid = (" " * (maxlen - n)) + " | "
      pad_tail = (" " * ("result".length - r[1].length)) + " |"
      puts "|#{r[0]}#{pad_mid}#{r[1]}#{pad_tail}"

      if is_header
        puts spacer
        is_header = false
      end
    end
    puts spacer unless ENV['tableformat'] == 'mkd'
  end

  tasks << :csv_output
  task :all => tasks

  # tempファイルに書き出し
  open(ENV['platforms_tmp'] ,"w") do |y|
    YAML.dump(platform, y)
  end

  path = {}

  scenarios.keys.each do |role|
    if scenarios[role].kind_of?(Array)

      scenarios[role].each do |host_alias|

        desc "Run serverspec to #{role}@#{host_alias}"

        RSpec::Core::RakeTask.new("#{role}::#{host_alias}".to_sym) do |t|

          path[role] = %W[
            #{ENV['specpath']}/#{role}/{default.rb}
            #{ENV['specpath']}/#{role}/{#{platform[host_alias.to_sym][:platform_name]}.rb}
            #{ENV['specpath']}/#{role}/{#{platform[host_alias.to_sym][:platform_detail_name]}.rb}
          ]

          t.pattern = path[role]
          raise "\e[31mspec file not found!![#{path.to_s}]\e[m" if Dir.glob(t.pattern).empty?
          t.fail_on_error = false
          ENV['TARGET_HOST'] = host_alias
          ENV['TARGET_SSH_HOST'] = platform[host_alias.to_sym][:host] || host_alias
        end
      end
    elsif scenarios[role].kind_of?(Hash)

      path[role] = {}

      scenarios[role].keys.each do |role_sub|

        scenarios[role][role_sub].each do |host_alias|

          desc "Run serverspec to #{role}::#{role_sub}@#{host_alias}"

          RSpec::Core::RakeTask.new("#{role}::#{role_sub}::#{host_alias}".to_sym) do |t|

            path[role][role_sub] = %W[
              #{ENV['specpath']}/#{role}/#{role_sub}/{default.rb}
              #{ENV['specpath']}/#{role}/#{role_sub}/{#{platform[host_alias.to_sym][:platform_name]}.rb}
              #{ENV['specpath']}/#{role}/#{role_sub}/{#{platform[host_alias.to_sym][:platform_detail_name]}.rb}
            ]

            t.pattern = path[role][role_sub]
            raise "\e[31mspec file not found!![#{path.to_s}]\e[m" if Dir.glob(t.pattern).empty?
            t.fail_on_error = false
            ENV['TARGET_HOST'] = host_alias
            ENV['TARGET_SSH_HOST'] = platform[host_alias.to_sym][:host] || host_alias
          end
        end
      end
    end
  end
end
