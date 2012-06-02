# -*- coding: utf-8 -*-
require 'test_helper'

class NekonekoGenTest < Test::Unit::TestCase
  def setup
    @file0 = File.join(File.dirname(__FILE__), 'class0.txt')
    @file1 = File.join(File.dirname(__FILE__), 'class1.txt')
    @file2 = File.join(File.dirname(__FILE__), 'class2.txt')
    @clean_files = []
  end
  def teardown
=begin    
    @clean_files.each do |file|
      if (File.exist?(file))
        File.unlink(file)
      end
    end
=end
  end
  
  def test_mlp
    gen2('mlp', {:method => :mlp})
    gen3('mlp', {:method => :mlp})    
  end
  def test_pa2
    gen2('pa2', {:method => :pa2})
    gen3('pa2', {:method => :pa2})    
  end
  def test_arow
    gen2('arow', {:method => :arow})
    gen3('arow',{:method => :arow})
  end
  
  def clean!(a, b)
    if (File.exist?(a))
      File.unlink(a)
    end
    if (File.exist?(b))
      File.unlink(b)
    end
  end    
  
  def gen2(prefix, options)
    p "---- #{prefix} generate 2class"
    output_file2 = File.join(Dir.tmpdir, "nekoneko_test2_#{prefix}_classifier.rb")
    output_file3 = File.join(Dir.tmpdir, "nekoneko_test3_#{prefix}_classifier.rb")
    
    clean!(output_file2, output_file3)
    @clean_files << output_file2
    @clean_files << output_file3    
    
    gen = NekonekoGen::TextClassifierGenerator.new(output_file2, [@file0, @file1], options)
    gen.train
    modname = gen.generate
    
    unless (File.exist?(output_file2))
      assert_equal "#{output_file2} not found", nil
    end
    
    begin
      load output_file2
      
      mod = Kernel.const_get(modname)
      ok = 0
      count = 0
      File.open(@file0) do |f|
        until f.eof?
          if (mod.predict(f.readline) == mod::CLASS0)
            ok += 1
          end
          count += 1
        end
      end
      puts "#{mod::LABELS[0]}: #{ok.to_f / count}"
      assert ok.to_f / count > 0.9
      
      ok = 0
      count = 0
      File.open(@file1) do |f|
        until f.eof?
          if (mod.predict(f.readline) == mod::CLASS1)
            ok += 1
          end
          count += 1
        end
      end
      puts "#{mod::LABELS[1]}: #{ok.to_f / count}"      
      assert ok.to_f / count > 0.9
    end
  end
  
  def gen3(prefix, options)
    p "---- #{prefix} generate 3class"
    output_file2 = File.join(Dir.tmpdir, "nekoneko_test2_#{prefix}_classifier.rb")
    output_file3 = File.join(Dir.tmpdir, "nekoneko_test3_#{prefix}_classifier.rb")

    clean!(output_file2, output_file3)
    @clean_files << output_file2
    @clean_files << output_file3    
    
    gen = NekonekoGen::TextClassifierGenerator.new(output_file3,
                                                   [@file0, @file1, @file2], options)
    gen.train
    modname = gen.generate
    
    unless (File.exist?(output_file3))
      assert_equal "#{output_file3} not found", nil
    end
    
    begin
      load output_file3

      mod = Kernel.const_get(modname)
      ok = 0
      count = 0
      File.open(@file0) do |f|
        until f.eof?
          if (mod.predict(f.readline) == mod::CLASS0)
            ok += 1
          end
          count += 1
        end
      end
      puts "#{mod::LABELS[0]}: #{ok.to_f / count}"
      assert ok.to_f / count > 0.9

      ok = 0
      count = 0
      File.open(@file1) do |f|
        until f.eof?
          if (mod.predict(f.readline) == mod::CLASS1)
            ok += 1
          end
          count += 1
        end
      end
      puts "#{mod::LABELS[1]}: #{ok.to_f / count}"
      assert ok.to_f / count > 0.9

      ok = 0
      count = 0
      File.open(@file2) do |f|
        until f.eof?
          if (mod.predict(f.readline) == mod::CLASS2)
            ok += 1
          end
          count += 1
        end
      end
      puts "#{mod::LABELS[2]}: #{ok.to_f / count}"
      assert ok.to_f / count > 0.9
    end
  end
end

