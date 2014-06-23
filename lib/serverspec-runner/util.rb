require 'net/ssh'
require 'net/ssh/shell'

module ServerspecRunner
  module Util

    def self.alternative_exec!(host, commands={}, options={})

      result = {}

      if host == 'localhost' || '127.0.0.1' || host == nil
        commands.each do |key,cmd|
          result[key] = { :stdout => `#{cmd}`.strip, :exit_status => $?, :exit_succeeded => ($? == 0) }
        end

        return result
      end

      options = Net::SSH::Config.for(host).merge(options)
      user    = options[:user] || Etc.getlogin

      puts "connecting #{host}..."

      Net::SSH.start(host, user, options) do |ssh|

        ssh.shell do |sh|
          commands.each do |key,cmd|

            stdout = ''
            stderr = ''
            exit_status = nil
            exit_succeeded = nil

            pr = sh.execute! cmd do |shell_process|
              shell_process.on_output do |pr, data|
                stdout = data
              end
            end
            result[key] = { :stdout => stdout.strip, :exit_status => pr.exit_status, :exit_succeeded => (pr.exit_status == 0) }
          end
          sh.execute! "exit"
        end
      end

      result
    end
  end
end
