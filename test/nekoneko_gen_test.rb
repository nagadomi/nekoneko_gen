# -*- coding: utf-8 -*-
require 'test_helper'

class NekonekoGenTest < Test::Unit::TestCase
  def setup
    @file0 = File.join(File.dirname(__FILE__), 'class0.txt')
    @file1 = File.join(File.dirname(__FILE__), 'class1.txt')
    @file2 = File.join(File.dirname(__FILE__), 'class2.txt')
    @output_file2 = File.join(Dir.tmpdir, "nekoneko_test2_classifier.rb")
    @output_file3 = File.join(Dir.tmpdir, "nekoneko_test3_classifier.rb")
  end
  def teardown
    cleanup!
  end
  def cleanup!
    begin
      File.unlink(@output_file2)
    rescue
    end
    begin
      File.unlink(@output_file3)
    rescue
    end
  end
  
  def test_gen2
    cleanup!
    
    gen = NekonekoGen::TextClassifierGenerator.new(@output_file2, [@file0, @file1])
    #gen.quiet = true
    gen.train(NekonekoGen::DEFAULT_ITERATION)
    gen.generate
    
    unless (File.exist?(@output_file2))
      assert_equal "#{@output_file2} not found", nil
    end
    
    begin
      load @output_file2
      
      ok = 0
      count = 0
      File.open(@file0) do |f|
        until f.eof?
          if (NekonekoTest2Classifier.predict(f.readline) == NekonekoTest2Classifier::CLASS0)
            ok += 1
          end
          count += 1
        end
      end
      puts "#{NekonekoTest2Classifier::LABELS[0]}: #{ok.to_f / count}"
      assert ok.to_f / count > 0.9

      ok = 0
      count = 0
      File.open(@file1) do |f|
        until f.eof?
          if (NekonekoTest2Classifier.predict(f.readline) == NekonekoTest2Classifier::CLASS1)
            ok += 1
          end
          count += 1
        end
      end
      puts "#{NekonekoTest2Classifier::LABELS[1]}: #{ok.to_f / count}"      
      assert ok.to_f / count > 0.9
    end
  end
  
  def test_gen3
    cleanup!
    
    gen = NekonekoGen::TextClassifierGenerator.new(@output_file3, [@file0, @file1, @file2])
    #gen.quiet = true
    gen.train(NekonekoGen::DEFAULT_ITERATION)
    gen.generate
    
    unless (File.exist?(@output_file3))
      assert_equal "#{@output_file3} not found", nil
    end
    
    begin
      load @output_file3
      
      ok = 0
      count = 0
      File.open(@file0) do |f|
        until f.eof?
          if (NekonekoTest3Classifier.predict(f.readline) == NekonekoTest3Classifier::CLASS0)
            ok += 1
          end
          count += 1
        end
      end
      puts "#{NekonekoTest3Classifier::LABELS[0]}: #{ok.to_f / count}"            
      assert ok.to_f / count > 0.9

      ok = 0
      count = 0
      File.open(@file1) do |f|
        until f.eof?
          if (NekonekoTest3Classifier.predict(f.readline) == NekonekoTest3Classifier::CLASS1)
            ok += 1
          end
          count += 1
        end
      end
      puts "#{NekonekoTest3Classifier::LABELS[1]}: #{ok.to_f / count}"
      assert ok.to_f / count > 0.9

      ok = 0
      count = 0
      File.open(@file2) do |f|
        until f.eof?
          if (NekonekoTest3Classifier.predict(f.readline) == NekonekoTest3Classifier::CLASS2)
            ok += 1
          end
          count += 1
        end
      end
      puts "#{NekonekoTest3Classifier::LABELS[2]}: #{ok.to_f / count}"
      assert ok.to_f / count > 0.9
    end
  end
end

