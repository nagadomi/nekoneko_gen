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
    def strip!
      @w.each {|w|
        w.reject!{|k,v|
          if (v.abs < Float::EPSILON)
            # p v
            true
          else
            false
          end            
        }
      }
      @w
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
    def parameter_code(lang, index_converter = lambda{|i| i})
      lang ||= :ruby
      case lang
      when :ruby
      else
        raise NotImplementedError
      end
      
      wvec = self.strip!.map {|w|
        w.reduce({}) {|h, kv| h[index_converter.call(kv[0])] = kv[1]; h }
      }
      <<CODE
  BIAS = #{self.bias.inspect}
  W = JSON.load(#{wvec.to_json.inspect})
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
  def self.classify(vec)
    if (K == 2)
      BIAS[0] + W[0].values_at(*vec).compact.reduce(0.0, :+) > 0.0 ? 0 : 1
    else
      W.each_with_index.map {|w, i|
        [BIAS[i] + w.values_at(*vec).compact.reduce(0.0, :+), i]
      }.max.pop
    end
  end
CODE
    end
  end
end
