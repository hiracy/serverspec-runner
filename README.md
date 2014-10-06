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

    $ vim  /path/to/your_serverspec_root/test_name/test_sub_name/your_serverspec_test.rb

Edit your infrastructure or middleware tests scenario to "scenario.yml".

```
test_name:             # test directory name
  test_sub_name:       # test sub directory name(not required)
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

<!-- See details to [here](http://serverspec.org/) -->

----

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
