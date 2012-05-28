# -*- coding: utf-8 -*-
require 'nekoneko_gen/version'
require 'nekoneko_gen/text_classifier_generator'
require 'optparse'
require 'fileutils'

module NekonekoGen
  DEFAULT_ITERATION = 20
  
  def self.run(argv)
    iteration = DEFAULT_ITERATION
    rubyfile = nil
    quiet = false

    $stdout.sync = true
    
    opt = OptionParser.new do |o|
      o.on('-n NAME', 'new classifier name') do |v|
        rubyfile = File.join(File.dirname(v), File.basename(v, ".*") + ".rb")
        FileUtils.touch(rubyfile)
      end
      o.on('-i N', "iteration count (default: #{DEFAULT_ITERATION})") do |v|
        iteration = v.to_i.abs
      end
      o.on('-q', "quiet") do
        quiet = true
      end
    end
    opt.version = NekonekoGen::VERSION
    opt.banner = "Usage: nekoneko_gen -n classifier_name file1 file2 [files...]"
    files = opt.parse(argv)
    
    unless (rubyfile)
      warn opt
      return -1
    end
    if (files.size < 2)
      warn opt
      return -1
    end
    files.each do |file|
      unless (File.readable?(file))
        warn "#{file}: error.\n"
        return -1
      end
    end
    
    gen = NekonekoGen::TextClassifierGenerator.new(rubyfile, files)
    if (quiet)
      gen.quiet = true
    end
    gen.train(iteration)
    gen.generate
    
    return 0
  end
end
