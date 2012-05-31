module NekonekoGen
  class Classifier
    def parameter_code(index_converter = nil)
      raise NotImplementedError
    end
    def classify_method_code
      raise NotImplementedError
    end
    def update(vec, label)
      raise NotImplementedError      
    end
  end
end
