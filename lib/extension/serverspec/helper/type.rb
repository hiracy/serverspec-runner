module Serverspec
  module Helper
    module Type
      types = %w(
        mysql
      )

      types.each {|type| require "extension/serverspec/type/#{type}" }

      types.each do |type|
        define_method type do |*args|
          name = args.first
          eval "Serverspec::Type::#{type.to_camel_case}.new(name)"
        end
      end
    end
  end
end
