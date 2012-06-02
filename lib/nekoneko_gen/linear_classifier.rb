# -*- coding: utf-8 -*-
require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), 'classifier'))

module NekonekoGen
  class LinearClassifier < Classifier
    attr_reader :w, :bias
    def dot(vec, w)
      dot = 0.0
      vec.each do |k, v|
        if (a = w[k])
          dot += a * v
        end
      end
      dot
    end
    def update(vec, label)
      loss = 0.0
      if (@k == 2)
        loss = update_at(0, vec, label)
      else
        s = 1.0 / @k
        @k.times do |i|
          loss += update_at(i, vec, label) * s
        end
      end
      loss
    end
    def features(i = -1)
      if (i < 0)
        w.reduce(0){|sum, v| sum + v.size }
      else
        w[i].size
      end
    end
    def parameter_code(lang = :ruby)
      lang ||= :ruby
      case lang
      when :ruby
      else
        raise NotImplementedError
      end
      <<CODE
  BIAS = #{self.bias.inspect}
  W = JSON.load(#{@w.to_json.inspect})
CODE
    end
    def classify_method_code(lang)
      lang ||= :ruby
      case lang
      when :ruby
      else
        raise NotImplementedError
      end
      <<CODE
  def self.classify(svec)
    if (K == 2)
      w0 = W[0]
      (BIAS[0] + svec.map{|k, v| v * w0[k]}.reduce(0.0, :+)) > 0.0 ? 0 : 1
    else
      W.each_with_index.map {|w, i|
        [BIAS[i] + svec.map{|k, v| v * w[k]}.reduce(0.0, :+), i]
      }.max.pop
    end
  end
CODE
    end
  end
end
