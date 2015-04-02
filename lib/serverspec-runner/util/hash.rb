class Hash
  def depth
    1 + (values.map{|v| Hash === v ? v.depth : 1}.max)
  end

  def deep_symbolize_keys
    self.each_with_object({}) do |(k, v), h|

      if v.is_a?(Array)
        v = v.map{|vv| vv.deep_symbolize_keys}
      elsif v.is_a?(Hash)
        v = v.deep_symbolize_keys
      end

      h[k.to_s.to_sym] = v
    end
  end
end
