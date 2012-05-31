# -*- coding: utf-8 -*-
require File.expand_path(File.join(File.dirname(__FILE__), 'linear_classifier'))

module NekonekoGen
  class PA < LinearClassifier
    C = 1.0
    NORM = 2.0 # norm + BIAS
    
    def initialize(k, options = {})
      @k = k
      @c = options[:c] || C
      @w = []
      @bias = []
      if (@k == 2)
        @w[0] = Hash.new(0.0)
        @bias[0] = 0.0
      else
        k.times do |i|
          @w[i] = Hash.new(0.0)
          @bias[i] = 0.0
        end
      end
      if options[:method]
        @tau = 
          case options[:method]
          when :pa
            lambda{|y, l| pa(y, l)}
          when :pa1
            lambda{|y, l| pa1(y, l)}          
          when :pa2
            lambda{|y, l| pa2(y, l)}          
          else
            lambda{|y, l| pa2(y, l)}          
          end
      else
        @tau = lambda{|y, l| pa2(y, l)}
      end
    end
    def pa2(y, l)
      y * (l / NORM + 0.5 / @c)
    end
    def pa1(y, l)
      y * [@c, (l / NORM)].min
    end
    def pa(y, l)
      y * l / NORM
    end
    def update_at(i, vec, label)
      y = label == i ? 1 : -1
      w = @w[i]
      score = @bias[i] + dot(vec, w)
      l = 1.0 - score * y
      if (l > 0.0)
        alpha = @tau.call(y, l)
        vec.each do |k, v|
          w[k] += alpha * v
        end
        @bias[i] += alpha
      end
      y * score < 0.0 ? 1.0 : 0.0
    end
  end
end
