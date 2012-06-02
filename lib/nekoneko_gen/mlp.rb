require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), 'classifier'))

module NekonekoGen
  # Multi Layer Perceptron
  class MLP < Classifier
    IR = 0.4
    HR = 0.1
    NOISE_VAR = 0.3
    MARGIN = 0.2
    DEFAULT_ITERATION = 40
    
    def default_hidden_unit
      @k
    end
    def initialize(k, n, options)
      @k = k
      @output_units = @k == 2 ? 1 : @k
      @hidden_units = (options[:c] || default_hidden_unit).to_i
      @input = []
      @hidden = []
      @input_bias = []
      @hidden_bias = []
      @hidden_units.times do |i|
        input = @input[i] = []
        n.times do |j|
          input[j] = rand_value
        end
        @input_bias[i] = rand_value
      end
      @output_units.times do |i|
        hidden = @hidden[i] = []
        @hidden_units.times do |j|
          hidden[j] = rand_value
        end
        @hidden_bias[i] = rand_value
      end
    end
    def update(vec, label)
      input_y = []
      hidden_y = []
      output_y = []
      
      input_y = @hidden_units.times.map do |i|
        w = @input[i]
        sigmoid(@input_bias[i] + vec.map{|k, v| w[k] * v}.reduce(:+) + noise)
      end
      hidden_y = @output_units.times.map do |i|
        @hidden_bias[i] + input_y.zip(@hidden[i]).map{|a, b| a * b }.reduce(:+)
      end
      output_y = @output_units.times.map do |i|
        sigmoid(hidden_y[i])
      end
      
      loss = 0.0
      dotrain = false
      if (@output_units == 1)
        if (output_y[0] > 0.5)
          l = 0
        else
          l = 1
        end
        if (label == 0)
          if (output_y[0] < 1.0 - MARGIN)
            dotrain = true
          end
        else
          if (output_y[0] > MARGIN)
            dotrain = true
          end
        end
        loss = (label == l) ? 0.0 : 1.0
      else
        max_p, l = output_y.each_with_index.max
        if (l == label)
          if (max_p < 1.0 - MARGIN)
            dotrain = true
          end
        else
          loss = 1.0
          dotrain = true
        end
      end
      if (dotrain)
        output_bp = @output_units.times.map do |i|
          y = hidden_y[i]
          yt = (label == i) ? 1.0 : 0.0
          expy = Math.exp(y)
           -((2.0 * yt - 1.0) * expy + yt) / (Math.exp(2.0 * y) + 2.0 * expy + 1.0)
        end
        hidden_bp = @hidden_units.times.map do |j|
          y = 0.0
          @output_units.times do |i|
            y += output_bp[i] * @hidden[i][j]
          end
          y * (1.0 - input_y[j]) * input_y[j]
        end
        @output_units.times do |j|
          hidden = @hidden[j]
          @hidden_units.times do |i|
            hidden[i] -= HR * input_y[i] * output_bp[j]
          end
          @hidden_bias[j] -= HR * output_bp[j]
        end
        @hidden_units.times do |i|
          input = @input[i]
          vec.each do |k, v|
            input[k] -= IR * v * hidden_bp[i]
          end
          @input_bias[i] -= IR * hidden_bp[i]
        end
      end
      loss
    end
    def features(i = -1)
      @input.map{|v| v.size }.reduce(:+)
    end
    def sigmoid(a)
      1.0 / (1.0 + Math.exp(-a))
    end
    def rand_value
      (rand - 0.5)
    end
    def noise
      (Math.sqrt(-2.0 * Math.log(rand)) * Math.sin(2.0 * Math::PI * rand)) * NOISE_VAR
    end
    def default_iteration
      DEFAULT_ITERATION
    end
    def parameter_code(lang = :ruby)
      lang ||= :ruby
      case lang
      when :ruby
      else
        raise NotImplementedError
      end
      <<CODE
  HIDDEN_UNITS = #{@hidden_units}
  INPUT_BIAS = #{@input_bias.inspect}
  HIDDEN_BIAS = #{@hidden_bias.inspect}
  INPUT_W = JSON.load(#{@input.to_json.inspect})
  HIDDEN_W = #{@hidden.inspect}
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
    input_y = []
    HIDDEN_UNITS.times do |i|
      w = INPUT_W[i]
      input_y[i] = sigmoid(INPUT_BIAS[i] +
                           svec.map{|k,v| v * w[k]}.reduce(0.0, :+))
    end
    if (K == 2)
      HIDDEN_BIAS[0] +
        input_y.zip(HIDDEN_W[0]).map{|a, b| a * b }.reduce(:+) > 0.0 ? 0 : 1
    else
      K.times.map{|i|
        [HIDDEN_BIAS[i] + input_y.zip(HIDDEN_W[i]).map{|a, b| a * b }.reduce(:+), i]
      }.max.pop
    end
  end
  def self.sigmoid(a)
    1.0 / (1.0 + Math.exp(-a))
  end
CODE
    end
  end
end
