# -*- coding: utf-8 -*-
module NekonekoGen
  class Classifier
    attr_reader :k
    def parameter_code(index_converter = nil)
      raise NotImplementedError
    end
    def classify_method_code
      raise NotImplementedError
    end
    def update(vec, label)
      raise NotImplementedError      
    end
    def features(i = -1)
      raise NotImplementedError      
    end
  end
end
