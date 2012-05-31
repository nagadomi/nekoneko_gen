# -*- coding: utf-8 -*-
require File.expand_path(File.join(File.dirname(__FILE__), 'linear_classifier'))
module NekonekoGen
  class Arow < LinearClassifier
    R = 6.0
    attr_accessor :k, :w, :bias
    def initialize(k, options = {})
      @r = options[:c] || R
      @k = k
      @cov = []
      @covb = []
      @w = []
      @bias = []
      if (@k == 2)
        @cov[0] = Hash.new(1.0)
        @w[0] = Hash.new(0.0)
        @covb[0] = 1.0
        @bias[0] = 0.0
      else
        k.times do |i|
          @cov[i] = Hash.new(1.0)
          @w[i] = Hash.new(0.0)
          @covb[i] = 1.0
          @bias[i] = 0.0
        end
      end
    end
    def update_at(i, vec, label)
      w = @w[i]
      cov = @cov[i]
      y = label == i ? 1 : -1
      score = @bias[i] + dot(vec, w)
      alpha = 1.0 - y * score
      if (alpha > 0.0)
        r_inv= 1.0 / @r
        var = vec.map {|k, v| cov[k] * v * v }.reduce(:+) + @covb[i]
        alpha *= (1.0 / (var + @r)) * y
        vec.each do |k, v|
          w[k] += alpha * cov[k] * v
          cov[k] = 1.0 / ((1.0 / cov[k]) + (v * v * r_inv))
        end
        @bias[i] += alpha * @covb[i]
        @covb[i] = 1.0 / ((1.0 / @covb[i]) + r_inv)
      end
      score * y < 0.0 ? 1.0 : 0.0
    end
  end
end
