require 'socket'
require 'serverspec-runner/util'

module ServerspecRunner
  module Detection

    def self.platform(host, ssh_options={}, properties)

      detected = {}

      sudo = properties[:nosudo] ? '' : 'sudo'
      properties[:sudo_prefix] = sudo + ' ' 

      commands = {
        :detect_platform_redhat             =>  'cat /etc/redhat-release 2> /dev/null',
        :detect_platform_debian             =>  'cat /etc/debian_version 2> /dev/null',
        :detect_hostname                    =>  'hostname 2> /dev/null',
        :detect_hostname_short              =>  'hostname -s 2> /dev/null',
      }

      executed = ServerspecRunner::Util.alternative_exec!(host, commands, ssh_options)

      # platform
      if executed[:detect_platform_redhat][:exit_succeeded]
        detected[:platform_name] = 'centos'

        if executed[:detect_platform_redhat][:stdout] =~ /^(CentOS release )(\d+).(\d+).*$/
          detected[:platform_detail_name] = "centos#{$2}"
        end
      elsif executed[:detect_platform_debian][:exit_succeeded]
        detected[:platform_name] = 'debian'

        if executed[:detect_platform_debian][:stdout] =~ /^(\d+).(\d+).(\d*)$/
          detected[:platform_detail_name] = "debian#{$1}"
        end
      end

      # hostname
      detected[:hostname] = executed[:detect_hostname][:stdout]
      detected[:hostname_short] = executed[:detect_hostname_short][:stdout]

      detected.merge(properties)
    end
  end
end
