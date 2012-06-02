# -*- coding: utf-8 -*-
require File.expand_path(File.join(File.dirname(__FILE__), 'arow'))
require File.expand_path(File.join(File.dirname(__FILE__), 'pa'))
require File.expand_path(File.join(File.dirname(__FILE__), 'mlp'))

module NekonekoGen
  module ClassifierFactory
    def self.create(k, n, options)
      method = options[:method] || :arow
      case (method)
      when :arow
        Arow.new(k, n, options)
      when :pa, :pa1, :pa2
        PA.new(k, n, options)
      when :mlp
        MLP.new(k, n, options)
      else
        raise ArgumentError
      end
    end
  end
end
