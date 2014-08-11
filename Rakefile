require 'rake'
require 'rspec/core/rake_task'
require 'yaml'
require 'csv'
require 'fileutils'
require 'net/ssh'
require 'open-uri'
require 'serverspec-runner'

desc "Run serverspec to all scenario"
task :spec => 'spec:all'

namespace :spec do

  ENV['EXEC_PATH'] = '/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin'

  ENV['specroot'] = ENV['specroot'] || "."
  ENV['specpath'] = "#{ENV['specroot']}/spec"

  ENV['ssh_options'] = ENV['ssh_options'] || "#{ENV['specroot']}/ssh_options.yml" || "#{File.dirname(__FILE__)}/ssh_options.yml"
  ENV['ssh_options'] = "#{File.dirname(__FILE__)}/ssh_options.yml" unless File.exists?(ENV['ssh_options'])
  ssh_options = YAML.load_file(ENV['ssh_options'])
  ENV['result_csv'] = ENV['result_csv'] || './_serverspec_result.csv'
  csv_file = ENV['result_csv']
  CSV.open(csv_file, 'w') { |w| w << ['description', 'result'] }
  ENV['explain'] = ENV['explain'] || "long"
  ENV['tableformat'] = ENV['tableformat'] || "aa"
  ENV['scenario'] = ENV['scenario'] || "./scenario.yml"

  def init_specpath(path)

    begin
      print "create spec tree to #{ENV['specpath']}?(y/n): "
      ans = STDIN.gets.strip
      exit 0 unless (ans == 'y' || ans == 'yes')
    rescue Exception
      exit 0
    end

    FileUtils.mkdir_p(path)
    FileUtils.cp_r("#{File.dirname(__FILE__)}/spec/.", path)

    puts("created to \"#{ENV['specpath']}\" !!")
  end

  def gen_exec_plan(parent, node, path, ssh_options, tasks, platform)

    if parent == nil
      abs_node = node
    else
      abs_node = parent[node]
    end

    if abs_node.kind_of?(Hash)
      abs_node.keys.each do |n|
        path <<  '::' unless path.empty?
        path << n.to_s
        path = gen_exec_plan(abs_node, n, path, ssh_options, tasks, platform)
      end
    elsif abs_node.kind_of?(Array)
      abs_node.each do |host_alias|
        if platform.include?(host_alias.to_sym)
          ssh_host = platform[host_alias.to_sym][:host]
        else
          platform[host_alias.to_sym] = {}
          ssh_host = host_alias
        end

        tasks << "#{path}::#{host_alias}"
        platform[host_alias.to_sym] = ServerspecRunner::Detection.platform(ssh_host, ssh_options, platform[host_alias.to_sym])
        return ''
      end
    end

    return path
  end

  def exec_tasks(parent, node, real_path, platform)

    if parent == nil
      abs_node = node
    else
      abs_node = parent[node]
    end
    
    if abs_node.kind_of?(Hash)
      abs_node.keys.each do |n|
        real_path << n
        real_path = exec_tasks(abs_node, n, real_path, platform)
      end
    elsif abs_node.kind_of?(Array)
      task_path = ''
      real_path.map.each do |p|
        task_path << '::' unless task_path.empty?
        task_path << p
      end

      abs_node.each do |host_alias|
        desc "Run serverspec to #{task_path}@#{host_alias}"
        RSpec::Core::RakeTask.new("#{task_path}::#{host_alias}".to_sym) do |t|

          fpath = task_path.gsub(/::/, '/')
          t.pattern = %W[
            #{ENV['specpath']}/#{fpath}/{default.rb}
            #{ENV['specpath']}/#{fpath}/{#{platform[host_alias.to_sym][:platform_name]}.rb}
            #{ENV['specpath']}/#{fpath}/{#{platform[host_alias.to_sym][:platform_detail_name]}.rb}
          ]

          raise "\e[31mspec file not found!![#{t.pattern.to_s}]\e[m" if Dir.glob(t.pattern).empty?
          t.fail_on_error = false
          ENV['TARGET_HOST'] = host_alias
          ENV['TARGET_SSH_HOST'] = platform[host_alias.to_sym][:host] || host_alias
        end
      end

      return []
    end

    return real_path
  end

  if !Dir.exists?(ENV['specpath'])
    init_specpath(ENV['specpath'])
    exit 0
  end

  if !ENV['tmpdir']
    ENV['platforms_tmp'] = "./_platforms.yml"
    ENV['scenario_tmp'] = "./_scenario.yml"
  else
    ENV['platforms_tmp'] = "#{ENV['tmpdir']}/_platforms.yml"
    ENV['scenario_tmp'] = "#{ENV['tmpdir']}/_scenario.yml"
  end

  scenarios = nil
  platform = {}

  if ENV['scenario'] =~ /^(http|https):\/\//
    open(ENV['scenario_tmp'], 'w') do |f|
      open(ENV['scenario']) do |data|
        f.write(data.read)
      end
    end

    ENV['scenario'] = ENV['scenario_tmp']
  end

  File.open(ENV['scenario'] || "#{ENV['specroot']}/scenario.yml") do |f|
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
  gen_exec_plan(nil, scenarios, '', ssh_options, tasks, platform)

  task :stdout do

    if ENV['tableformat'] == 'bool'

      ret = 'ok'
      CSV.foreach(csv_file) do |r|
        ret = 'ng' if r[1] == 'NG'
      end

      puts ret
    elsif ENV['tableformat'] == 'csv'
      CSV.foreach(csv_file) do |r|
        puts "#{r[0].strip}#{r[1].empty? ? '': ','}#{r[1]}"
      end
    else
      maxlen = 0
      CSV.foreach(csv_file) do |r|
        n =  r[0].each_char.map{|c| c.bytesize == 1 ? 1 : 2}.reduce(0, &:+)
        maxlen = n if n > maxlen
      end
  
      pad_spaces = 4
  
      spacer = nil
      if ENV['tableformat'] == 'mkd'
        spacer = "|:" + ("-" * maxlen) + "|:" + ("-" * "result".length) + ":|"
      elsif ENV['tableformat'] == 'aa'
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
  end

  tasks << :stdout
  task :all => tasks

  # tempファイルに書き出し
  open(ENV['platforms_tmp'] ,"w") do |y|
    YAML.dump(platform, y)
  end

  path = {}
  exec_tasks(nil, scenarios, [], platform)
end
