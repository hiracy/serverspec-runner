require 'rake'
require 'rspec/core/rake_task'
require 'yaml'
require 'csv'
require 'fileutils'
require 'net/ssh'
require 'open-uri'
require 'serverspec-runner'
require 'serverspec-runner/util/hash'
require 'serverspec-runner/ansible/inventory'

desc "Run serverspec to all scenario"
task :spec => 'spec:all'

namespace :spec do

  ENV['EXEC_PATH'] = '/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin'

  if ENV['specroot'] == nil
    if ENV['scenario'] != nil
      ENV['specroot'] = "#{File.dirname(ENV['scenario'])}"
    else
      ENV['specroot'] = '.'
    end
  end

  Dir.chdir(ENV['specroot']) if Dir.exists?(ENV['specroot'])

  ENV['specpath'] = "#{ENV['specroot']}/spec"
  ENV['ssh_options'] = ENV['ssh_options'] || "#{ENV['specroot']}/ssh_options_default.yml" || "#{File.dirname(__FILE__)}/ssh_options_default.yml"
  ENV['ssh_options'] = "#{File.dirname(__FILE__)}/ssh_options_default.yml" unless File.exists?(ENV['ssh_options'])
  ssh_options = YAML.load_file(ENV['ssh_options'])
  ENV['result_csv'] = ENV['result_csv'] || './_serverspec_result.csv'
  csv_file = ENV['result_csv']
  CSV.open(csv_file, 'w') { |w| w << ['description', 'result'] }
  ENV['explain'] = ENV['explain'] || "short"
  ENV['tableformat'] = ENV['tableformat'] || "aa"
  ENV['scenario'] = File.expand_path(ENV['scenario'] || "./scenario.yml")
  ENV['inventory'] = File.expand_path(ENV['inventory']) if ENV['inventory']

  def init_specpath(path, only_activate)

    abs_path = File::expand_path(path)

    unless only_activate
      begin
        print "want to create spec-tree to #{abs_path}? (y/n): "
        ans = STDIN.gets.strip
        exit 0 unless (ans == 'y' || ans == 'yes')
      rescue Exception
        exit 0
      end
    end

    FileUtils.mkdir_p("#{path}/lib")
    FileUtils.cp("#{File.dirname(__FILE__)}/scenario.yml", path)
    FileUtils.cp("#{File.dirname(__FILE__)}/ssh_options_default.yml", path)
    FileUtils.cp("#{File.dirname(__FILE__)}/.rspec", path)
    FileUtils.cp_r("#{File.dirname(__FILE__)}/spec", path)
    FileUtils.cp_r("#{File.dirname(__FILE__)}/lib/extension", "#{path}/lib")

    puts("Please edit \"#{abs_path}/scenario.yml\" and change directory to \"#{abs_path}\" and exec \"serverspec-runner\" command !!")
  end

  def gen_exec_plan(parent, node, path, ssh_options, tasks, platform)

    if parent == nil
      abs_node = node
    else
      abs_node = parent[node]
    end

    if abs_node.kind_of?(Hash)
      abs_node.keys.each do |n|
        path.push(n.to_s)
        gen_exec_plan(abs_node, n, path, ssh_options, tasks, platform)
      end

      path.pop
    elsif abs_node.kind_of?(Array)
      abs_node.each do |host_alias|
        if platform.include?(host_alias.to_sym)
          ssh_host = platform[host_alias.to_sym][:host]
        else
          platform[host_alias.to_sym] = {}
          ssh_host = host_alias
        end

        platform[host_alias.to_sym][:ssh_opts].each { |k, v| ssh_options[k.to_sym] = v } if platform[host_alias.to_sym].include?(:ssh_opts)
        tasks << "#{path.join('::')}::#{host_alias}"
      end

      path.pop
    end
  end

  def exec_tasks(parent, node, real_path, platform)
    spec_file_pattern = ENV['pattern'] || "**/*.rb"
    spec_file_exclude_pattern = ENV['exclude_pattern']

    if parent == nil
      abs_node = node
    else
      abs_node = parent[node]
    end

    if abs_node.kind_of?(Hash)
      abs_node.keys.each do |n|
        real_path.push(n)
        exec_tasks(abs_node, n, real_path, platform)
      end

      real_path.pop
    elsif abs_node.kind_of?(Array)
      task_path = "#{real_path.join('::')}"

      abs_node.each do |host_alias|
        desc "Run serverspec to #{task_path}@#{host_alias}"
        RSpec::Core::RakeTask.new("#{task_path}::#{host_alias}".to_sym) do |t|

          fpath = task_path.gsub(/::/, '/')

          if Dir.exists?("#{ENV['specpath']}/#{fpath}")
            t.pattern = "#{ENV['specpath']}/#{fpath}/#{spec_file_pattern}"

            if spec_file_exclude_pattern
              t.exclude_pattern = "#{ENV['specpath']}/#{fpath}/#{spec_file_exclude_pattern}"
            end
          elsif File.file?("#{ENV['specpath']}/#{fpath}.rb")
            t.pattern = %W[
              #{ENV['specpath']}/#{fpath}.rb
            ]
          end

          raise "\e[31mspec file not found!![#{t.pattern.to_s}]\e[m" if Dir.glob(t.pattern).empty?
          t.fail_on_error = false
          ENV['TARGET_HOST'] = host_alias
          ENV['TARGET_SSH_HOST'] = platform[host_alias.to_sym][:host] || host_alias
          if platform[host_alias.to_sym].key?(:ssh_opts) && platform[host_alias.to_sym][:ssh_opts].key?(:port)
            ENV['TARGET_CONNECTION'] = 'ssh'
          end
        end
      end

      real_path.pop
    end
  end

  if !Dir.exists?(ENV['specpath'])
    init_specpath(ENV['specroot'], false)
    exit 0
  elsif ENV['activate_specroot']
    init_specpath(ENV['specroot'], true)
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

  if !File.file?(ENV['scenario']) && !File.file?("#{ENV['specroot']}/scenario.yml")
    print "\e[31m"
    puts "scenario.yml is not found.(--help option can display manual))"
    print "\e[m"
    exit 1
  end

  File.open(ENV['scenario'] || "#{ENV['specroot']}/scenario.yml") do |f|
    YAML.load_stream(f).each_with_index do |data, idx|
      if idx == 0
        scenarios = data
      else
        if data != nil
          data.each do |k, v|
            platform[k.to_sym] = v.deep_symbolize_keys
          end
        end
      end
    end
  end

  if ENV['inventory']
    if !File.file?(ENV['inventory'])
      print "\e[31m"
      puts "inventory file is not found.(--help option can display manual))"
      print "\e[m"
      exit 1
    end

    platform = Inventory.inventory_to_platform(YAML.load_file(ENV['inventory']))
  end

  if !scenarios
    print "\e[31m"
    puts "scenario is empty."
    print "\e[m"
    exit 1
  end

  tasks = []
  gen_exec_plan(nil, scenarios, [], ssh_options, tasks, platform)

  task :stdout do
    ENV['is_example_error'] = 'true' if CSV.foreach(csv_file).any? { |c| c.size > 1 && c[1] == 'NG' }

    if ENV['tableformat'] == 'none'
    elsif ENV['tableformat'] == 'bool'

      ret = 'ok'
      CSV.foreach(csv_file) do |r|
        ret = 'ng' if r[1] == 'NG'
      end

      puts ret
    elsif ENV['tableformat'] == 'csv'

      maxrows = 0
      CSV.foreach(csv_file) do |r|
        maxrows = r[2].to_i if r[2].to_i > maxrows
      end
      maxrows += 1 # host row

      CSV.foreach(csv_file) do |r|
        pad_comma = ',' * (maxrows - r[0].split(',').length)
        puts "#{r[0]}#{pad_comma},#{r[1]}"
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

        if r[1] == 'OK'
          s_effect = "\e[32m"
          e_effect = "\e[m"
          r[1] = '  ' + r[1]
        elsif  r[1] == 'NG'
          s_effect = "\e[31m"
          e_effect = "\e[m"
          r[1] = '  ' + r[1]
        end

        pad_mid = (" " * (maxlen - n)) + " | "
        pad_tail = (" " * ("result".length - r[1].length)) + " |"

        puts "|#{s_effect}#{r[0]}#{e_effect}#{pad_mid}#{s_effect}#{r[1]}#{e_effect}#{pad_tail}"

        if is_header
          puts spacer
          is_header = false
        end
      end
      puts spacer unless ENV['tableformat'] == 'mkd'
    end
  end

  task :exit do
    exit(1) if !ENV['ignore_error_exit'] && ENV['is_example_error']
  end

  exec_tasks = []
  if ENV['parallels']
    processes = ENV['parallels'].to_i

    split_group = []
    groups = 0
    tasks.each_with_index do |t,pos|

      split_group << t

      if pos % processes == 0 || pos == tasks.length - 1
        multitask "parallel_tasks_#{groups}".to_s => split_group
        groups += 1
        split_group = []
      end
    end

    groups.times {|i| exec_tasks << "parallel_tasks_#{i}" }
  else
    exec_tasks = tasks
  end

  exec_tasks << :stdout
  exec_tasks << :exit
  task :all => exec_tasks

  # tempファイルに書き出し
  open(ENV['platforms_tmp'] ,"w") do |y|
    YAML.dump(platform, y)
  end

  path = {}
  exec_tasks(nil, scenarios, [], platform)
end
