module Serverspec::Type
  class File < Base
    def text?
      @runner.check_file_is_text(@name)
    end
  end
end
