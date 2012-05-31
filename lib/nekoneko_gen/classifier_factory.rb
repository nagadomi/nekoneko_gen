require File.expand_path(File.join(File.dirname(__FILE__), 'arow'))
require File.expand_path(File.join(File.dirname(__FILE__), 'pa'))

module NekonekoGen
  module ClassifierFactory
    def self.create(k, options)
      method = options[:method] || :arow
      case (method)
      when :arow
        Arow.new(k, options)
      when :pa, :pa1, :pa2
        PA.new(k, options)
      end
    end
  end
end
