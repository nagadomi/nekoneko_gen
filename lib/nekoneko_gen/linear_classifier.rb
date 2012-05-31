module NekonekoGen
  class LinearClassifier
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
  end
end
