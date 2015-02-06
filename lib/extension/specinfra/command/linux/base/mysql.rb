class Specinfra::Command::Linux::Base::Mysql < Specinfra::Command::Base
  class << self
    def check_is_replicated(master=nil, user=nil, password=nil, port=nil)
      opt_user     = "--user=#{user} " || ''
      opt_password = "--password=#{password} " || ''
      opt_port     = "--port=#{port} " || ''

      cmd = ''
      cmd += "echo 'show slave status \\G;' | mysql #{opt_user} #{opt_password} #{opt_port} | "
      cmd += "grep -e 'Slave_IO_Running: Yes' -e 'Slave_SQL_Running: Yes' -e 'Master_Host: #{master}' | "
      cmd += "wc -l | grep -w 3"
      cmd
    end
  end
end
