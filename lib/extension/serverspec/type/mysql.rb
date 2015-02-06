module Serverspec::Type
  class Mysql < Base
    def replicated?(master=nil, user=nil, password=nil, port=nil)
      @runner.check_mysql_is_replicated(master, user, password, port)
    end
  end
end
