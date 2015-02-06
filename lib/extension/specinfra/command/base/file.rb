class Specinfra::Command::Base::File < Specinfra::Command::Base
  class << self
    def check_is_text(file)
      "file #{escape(file)} | egrep ' text$'"
    end
  end
end		
