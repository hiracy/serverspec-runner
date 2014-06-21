class Hash
  def depth
    1 + (values.map{|v| Hash === v ? v.depth : 1}.max)
  end
end
