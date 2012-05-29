# -*- coding: utf-8 -*-
module NekonekoGen
  class Arow
    R = 6.0
    attr_accessor :k, :w
    def initialize(k, options = {})
      @r = options[:r] || R
      @k = k
      @cov = []
      @w = []
      if (@k == 2)
        @cov[0] = Hash.new(1.0)
        @w[0] = Hash.new(0.0)
      else
        k.times do |i|
          @cov[i] = Hash.new(1.0)
          @w[i] = Hash.new(0.0)
        end
      end
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
    def strip!
      @w.each do |w|
        w.reject!{|k,v| v.abs <= Float::EPSILON }
      end
      @w
    end
    
    private
    def dot(vec, w)
      dot = 0.0
      vec.each do |k, v|
        if (a = w[k])
          dot += a * v
        end
      end
      dot
    end
    def update_at(i, vec, label)
      w = @w[i]
      cov = @cov[i]
      y = label == i ? 1 : -1
      score = dot(vec, w)
      alpha = 1.0 - y * score
      if (alpha > 0.0)
        r_inv= 1.0 / @r
        var = vec.map {|k, v| cov[k] * v * v }.reduce(:+)
        alpha *= (1.0 / (var + @r)) * y
        vec.each do |k, v|
          w[k] += alpha * cov[k] * v
          cov[k] = 1.0 / ((1.0 / cov[k]) + (v * v * r_inv))
        end
      end
      score * y < 0.0 ? 1.0 : 0.0
    end
  end
end
