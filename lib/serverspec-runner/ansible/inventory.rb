module Inventory
  def self.inventory_to_platform(data)
    platform = {}

    data.each do |k, v|
      v.each do |gk, gv|
        if gk == 'hosts'
          if gv.kind_of?(Hash)
            gv.each do |hk, hv|
              platform[hk.to_sym] = unless hv.nil?
                               convert_ssh_opt(v['vars']).merge(convert_ssh_opt(hv))
                             else
                               convert_ssh_opt(v['vars'])
                             end
            end
          elsif gv.kind_of?(Array)
            gv.each do |h|
              platform[h.to_sym] = convert_ssh_opt(v['vars'])
            end
          end
        end
      end
    end

    platform
  end

  private

  def self.convert_ssh_opt(src)
    serverspec_opt = {}
    serverspec_opt[:ssh_opts] = {}
    src.each do |k, v|
      case k
      when 'ansible_host'
        serverspec_opt[:host] = v
      when 'ansible_user'
        serverspec_opt[:ssh_opts][:user] = v
      when 'ansible_port'
        serverspec_opt[:ssh_opts][:port] = v
      when 'ansible_ssh_private_key_file'
        serverspec_opt[:ssh_opts][:keys] = Array(v)
      when 'ansible_ssh_pass'
        serverspec_opt[:ssh_opts][:password] = v
      when 'ansible_ssh_common_args'
        if v.include?('StrictHostKeyChecking=no')
          serverspec_opt[:ssh_opts][:verify_host_key] = false
        elsif v.include?('UserKnownHostsFile=/dev/null')
          serverspec_opt[:ssh_opts][:user_known_hosts_file] = '/dev/null'
        end
      end
    end

    serverspec_opt
  end
end
