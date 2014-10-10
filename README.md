serverspec-runner
======================

Simple execution framework for [serverspec](http://serverspec.org/).

----

## Installation

    $ gem install serverspec-runner

----

## Usage

initialize spec direcotries and create skeleton-specfiles.

    $ serverspec-runner -r /path/to/your_serverspec_root

Edit your [spec-files](http://serverspec.org/resource_types.html).

    $ vim  /path/to/your_serverspec_root/test_top_dir/.../your_serverspec_test.rb

Edit your infrastructure or middleware tests scenario to "scenario.yml".

```
test_top_dir:          # test directory top
    :                  # test hierarchy directories
  test_bottom_dir:     # test directory bottom
    - servername       # ssh-accessible ip address or fqdn. or alias
    - :
  - :
:
---
servername:            # alias name(not required)
  host: 192.168.0.11   # ssh-accessible ip address or fqdn(required if alias exist)
  ssh_opts:            # ssh options(not required)
    port: 22           # ssh port option(not required)
    user: "anyone"     # ssh user option(not required)
      :                # any other Net::SSH Options(not required)
  any_attribute: "aaa" # host attributes. left example available to get "property[:servername][:any_attribute]" from code(not required)
  :
:
```

do tests.

    $ serverspec-runner -r /path/to/your_serverspec_root -s /path/to/your_scenario.yml

or

    $ cd /path/to/your_serverspec_root && serverspec-runner

You can also specify [ssh_options.yml](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html)(Net::SSH options) file by "-o" option for default ssh options.

    $ serverspec-runner -s /path/to/your_scenario.yml -o /path/to/your_ssh_options.yml

For example. You write serverspec code like this.

```
describe "nginx" do
  describe "check install" do
    describe package('nginx') do
      it { should be_installed }
    end
  end
    
  describe "check running" do
    describe process('nginx') do
      it { should be_running }
    end
  end
    
  describe "check process" do
    describe process('nginx') do
      it { should be_enabled }
    end
  end

  describe "worker_connection:1024" do
    describe file('/etc/nginx/nginx.conf') do
      it { should contain "worker_connections 1024;" }
    end
  end

  describe "logrotate interval" do
    describe file('/etc/logrotate.d/nginx') do
      it { should contain "rotate 14" }
    end
  end
end
```

You can get the following outputs.

* serverspec-runner -t aa  : asci-art table(default)
```
+------------------------------------------+
|description                      | result |
+------------------------------------------+
|example@anyhost-01(192.168.1.11) |        |
|  nginx check install            | OK     |
|  nginx check running            | NG     |
|  nginx check process            | OK     |
|  nginx worker_connection:1024   | OK     |
|  nginx logrotate interval       | NG     |
|example@anyhost-02(192.168.1.12) |        |
|  nginx check install            | OK     |
|  nginx check running            | NG     |
|  nginx check process            | OK     |
|  nginx worker_connection:1024   | OK     |
|  nginx logrotate interval       | NG     |
+------------------------------------------+

```

* serverspec-runner -t mkd : markdown table format
```
|description                       | result |
|:---------------------------------|:------:|
|example@anyhost-01(192.168.1.11)  |        |
|  nginx check install             | OK     |
|  nginx check running             | NG     |
|  nginx check process             | OK     |
|  nginx worker_connection:1024    | OK     |
|  nginx logrotate interval        | NG     |
|example@anyhost-02(192.168.1.12)  |        |
|  nginx check install             | OK     |
|  nginx check running             | OK     |
|  nginx check process             | OK     |
|  nginx worker_connection:1024    | OK     |
|  nginx logrotate interval        | NG     |
```

this text parsed for markdown to that

|description                       | result |
|:---------------------------------|:------:|
|example@anyhost-01(192.168.1.11)  |        |
|  nginx check install             | OK     |
|  nginx check running             | NG     |
|  nginx check process             | OK     |
|  nginx worker_connection:1024    | OK     |
|  nginx logrotate interval        | NG     |
|example@anyhost-02(192.168.1.12)  |        |
|  nginx check install             | OK     |
|  nginx check running             | OK     |
|  nginx check process             | OK     |
|  nginx worker_connection:1024    | OK     |
|  nginx logrotate interval        | NG     |

* serverspec-runner -t bool : only 'ok' or 'ng' result string.t
You can use for cluster monitoring system health.
```
ng
```

* serverspec-runner --result_csv [csv file path] : output result CSV file
You can get result CSV format file.


For more detail. You can see from `serverspec-runner -h` command.

----

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
