# -*- coding: utf-8 -*-
require 'nkf'
require 'bimyou_segmenter'

require File.expand_path(File.join(File.dirname(__FILE__), 'classifier_factory'))

module NekonekoGen
  class TextClassifierGenerator
    attr_accessor :quiet
    def initialize(filename, files, options = {})
      @quiet = false
      @options = options
      @filename = filename
      @files = files
      @word2id = {}
      @id2word = {}
      @classifier = ClassifierFactory.create(files.size, options)
      @name = safe_name(@filename).split("_").map(&:capitalize).join
      @labels = files.map {|file| "#{safe_name(file).upcase}"}
    end
    def train(iteration = nil)
      iteration ||= @classifier.default_iteration
      data = []
      @classifier.k.times do |i|
        t = Time.now
        data[i] = []
        print "loading #{@files[i]}... "
        
        content = nil
        File.open(@files[i]) do |f|
          content = f.read
        end
        content = NKF.nkf('-wZX', content).downcase
        content.lines do |line|
          vec = fv(line.chomp)
          if (vec.size > 0)
            data[i] << normalize(vec)
          end
        end
        puts sprintf("%.4fs", Time.now - t)
      end
      
      samples = data.map{|v| v.size}.min
      iteration.times do |step|
        loss = 0.0
        c = 0
        t = Time.now
        print sprintf("step %3d...", step)
        
        @classifier.k.times.map do |i|
          sampling(data[i], samples).map {|vec| [vec, i] }
        end.flatten(1).shuffle!.each do |v|
          loss += @classifier.update(v[0], v[1])
          c += 1
        end
        print sprintf(" %.6f, %.4fs\n", 1.0 - loss / c.to_f, Time.now - t)
      end
      if (@classifier.k > 2)
        @classifier.k.times do |i|
          puts "#{@labels[i]} : #{@classifier.features(i)} features"
        end
      else
        puts "#{@labels[0]}, #{@labels[1]} : #{@classifier.features(0)} features"
      end
      puts "done nyan! "
    end
    def generate(lang = :ruby)
      lang ||= :ruby
      case lang
      when :ruby
        generate_ruby_code
      else
        raise NotImplementedError
      end
      @name
    end
    def generate_ruby_code
      labels = @labels.each_with_index.map{|v, i| "  #{v} = #{i}"}.join("\n")
      File.open(@filename, "w") do |f|
        f.write <<MODEL
# -*- coding: utf-8 -*-
require 'rubygems'
require 'json'
require 'nkf'
require 'bimyou_segmenter'

class #{@name}
  def self.k
    K
  end
  def self.predict(text)
    classify(fv(NKF::nkf('-wZX', text).downcase))
  end
#{labels}
  LABELS = #{@labels.inspect}
  K = #{@classifier.k}
  private
  def self.fv(text)
    prev = nil
    BimyouSegmenter.segment(text,
                            :white_space => true,
                            :symbol => true).map do |word|
      if (prev)
        if (NGRAM_TARGET =~ word)
          nword = [prev + word, word]
          prev = word
          nword
        else
          prev = nil
          word
        end
      else
        if (NGRAM_TARGET =~ word)
          prev = word
        end
        word
      end
    end.flatten
  end
#{@classifier.classify_method_code(:ruby)}
  NGRAM_TARGET = Regexp.new('(^[ァ-ヾ]+$)|(^[a-zA-Z\\-_ａ-ｚＡ-Ｚ‐＿0-9０-９]+$)|' +
                         '(^[々〇ヵヶ' + [0x3400].pack('U') + '-' + [0x9FFF].pack('U') +
                         [0xF900].pack('U') + '-' + [0xFAFF].pack('U') +
                            [0x20000].pack('U') + '-' + [0x2FFFF].pack('U') + ']+$)')
#{@classifier.parameter_code(:ruby, lambda{|id| id2word(id) })}
end
MODEL
      end
    end

    private
    def id2word(id)
      @id2word[id]
    end
    def word2id(word)
      if (word_id = @word2id[word])
        word_id
      else
        word_id = @word2id.size
        @word2id[word] = word_id
        @id2word[word_id] = word
        word_id
      end
    end
    def lemmatize(word)
      if (word =~ /^[a-z\-_]+$/)
        LEMMATIZATION_RULE.each do |reg|
          if (word.match(reg[0]))
            return reg[1].map{|b| word.gsub(reg[0], b)}
          end
        end
        word
      else
        word
      end
    end
    def fv(text)
      vec = Hash.new(0)
      prev = nil
      BimyouSegmenter.segment(text,
                              :white_space => true,
                              :symbol => true).map do |word|
        if (prev)
          if (NGRAM_TARGET =~ word)
            nword = [prev + word, word]
            prev = word
            nword
          else
            prev = nil
            word
          end
        else
          if (NGRAM_TARGET =~ word)
            prev = word
          end
          word
        end
      end.flatten.reject do |word|
        word.empty? || STOP_WORDS[word] || word.match(WHITE_SPACE) || word.match(SYMBOL)
      end.each do |word|
        vec[word2id(word)] += 1
      end
      vec
    end
    def normalize(vec)
      norm = Math.sqrt(vec.values.map{|v| v * v }.reduce(:+))
      if (norm > 0.0)
        s = 1.0 / norm
        vec.each do |k, v|
          vec[k] = v * s
        end
      end
      vec
    end
    def sampling(a, n)
      if (a.size < n)
        over_sampling(a, n)
      else
        under_sampling(a, n)
      end
    end
    def over_sampling(a, n)
      if (a.size == n)
        a
      else
        if (a.respond_to?(:sample))
          a + a.sample(n - a.size)
        else
          a + a.shuffle[0, n - a.size]
        end
      end
    end
    def under_sampling(a, n)
      if (a.size == n)
        a
      else
        if (a.respond_to?(:sample))
          a.sample(n)
        else
          a.shuffle[0, n]
        end
      end
    end
    def safe_name(filename)
      File.basename(filename, ".*").gsub(/[\-\.]/,'_').gsub(/[^a-zA-Z_0-9]/, '')
    end
    def puts(s)
      unless (@quiet)
        Kernel.puts s
      end
    end
    def print(s)
      unless (@quiet)
        Kernel.print s
      end
    end
    SYMBOL = Regexp.new('^[^々〇' + [0x3400].pack('U') + '-' + [0x9FFF].pack('U') +
                        [0xF900].pack('U') + '-' + [0xFAFF].pack('U') +
                        [0x20000].pack('U') + '-' + [0x2FFFF].pack('U') +
                        '\s　ぁ-ゞァ-ヾa-zA-Zａ-ｚＡ-Ｚ0-9０-９]+$')
    WHITE_SPACE = /[\s　]/
    NGRAM_TARGET = Regexp.new('(^[ァ-ヾ]+$)|(^[a-zA-Z\-_ａ-ｚＡ-Ｚ‐＿0-9０-９]+$)|' +
                              '(^[々〇ヵヶ' + [0x3400].pack('U') + '-' + [0x9FFF].pack('U') +
                              [0xF900].pack('U') + '-' + [0xFAFF].pack('U') +
                              [0x20000].pack('U') + '-' + [0x2FFFF].pack('U') + ']+$)')
    LEMMATIZATION_RULE = [[/shes$/, ["sh"]], [/ches$/, ["ch"]], [/zed$/, ["zed"]], [/zes$/, ["z"]], [/ses$/, ["s"]], [/ing$/, [""]], [/ves$/, ["f"]], [/xes$/, ["x"]], [/ies$/, ["y"]], [/est$/, ["e", ""]], [/men$/, ["man"]], [/es$/, ["e", ""]], [/ed$/, ["e", ""]], [/er$/, ["e", ""]], [/s$/, [""]]]
    STOP_WORDS = {"の"=>1, "に"=>1, "て"=>1, "が"=>1, "た"=>1, "は"=>1, "で"=>1, "を"=>1, "と"=>1, "か"=>1, "も"=>1, "ない"=>1, "だ"=>1, "な"=>1, "です"=>1, "から"=>1, "ます"=>1, "う"=>1, "けど"=>1, "って"=>1, "ば"=>1, "よ"=>1, "まし"=>1, "たら"=>1, "ね"=>1, "ん"=>1, "なら"=>1, "でしょ"=>1, "とか"=>1, "じゃ"=>1, "まで"=>1, "ので"=>1, "ませ"=>1, "だけ"=>1, "へ"=>1, "なく"=>1, "という"=>1, "や"=>1, "でも"=>1, "ござい"=>1, "し"=>1, "たい"=>1, "だろ"=>1, "なかっ"=>1, "ある"=>1, "ず"=>1, "たり"=>1, "だっ"=>1, "しか"=>1, "くらい"=>1, "かも"=>1, "ながら"=>1, "でし"=>1, "また"=>1, "より"=>1, "のに"=>1, "わ"=>1, "など"=>1, "として"=>1, "ぬ"=>1, "あっ"=>1, "らしい"=>1, "ばかり"=>1, "ほど"=>1, "ぞ"=>1, "しかし"=>1, "なけれ"=>1, "ただ"=>1, "つ"=>1, "けれども"=>1, "んで"=>1, "ぐらい"=>1, "なんて"=>1, "について"=>1, "そうして"=>1, "ましょ"=>1, "さえ"=>1, "のみ"=>1, "たく"=>1, "あり"=>1, "る"=>1, "なんか"=>1, "べき"=>1, "だって"=>1, "それとも"=>1, "ちゃ"=>1, "なぁ"=>1, "それから"=>1, "さ"=>1, "ぜ"=>1, "によって"=>1, "ねえ"=>1, "っけ"=>1, "やら"=>1, "だから"=>1, "とも"=>1, "いや"=>1, "なり"=>1, "それでも"=>1, "なあ"=>1, "まい"=>1, "つつ"=>1, "そして"=>1, "それで"=>1, "かい"=>1, "すると"=>1, "しかも"=>1, "あろ"=>1, "らしく"=>1, "ずつ"=>1, "り"=>1, "たる"=>1, "又"=>1, "ねぇ"=>1, "に対して"=>1, "け"=>1, "こそ"=>1, "もしくは"=>1, "なきゃ"=>1, "だら"=>1, "そこで"=>1, "すら"=>1, "実は"=>1, "ところが"=>1, "なる"=>1, "による"=>1, "御座い"=>1, "じゃん"=>1, "つまり"=>1, "けれど"=>1, "ただし"=>1, "だの"=>1, "たかっ"=>1, "ざる"=>1, "ごとく"=>1, "に対する"=>1, "とかいう"=>1, "かしら"=>1, "なくっ"=>1, "そりゃ"=>1, "または"=>1, "べ"=>1, "にて"=>1, "において"=>1, "たろ"=>1, "無い"=>1, "あれ"=>1, "なぞ"=>1, "っと"=>1, "き"=>1, "にとって"=>1, "たって"=>1, "じ"=>1, "あるいは"=>1, "ど"=>1, "っす"=>1, "だり"=>1, "又は"=>1, "ばっかり"=>1, "てか"=>1, "けども"=>1, "と共に"=>1, "れ"=>1, "なかろ"=>1, "なお"=>1, "ものの"=>1, "に関する"=>1, "ばっか"=>1, "こうして"=>1, "程"=>1, "べし"=>1, "たとえば"=>1, "ども"=>1, "一方"=>1, "それでは"=>1, "かつ"=>1, "やし"=>1, "だけど"=>1, "なんぞ"=>1, "べく"=>1, "迄"=>1, "如く"=>1, "ってか"=>1, "すなわち"=>1, "さて"=>1, "どころか"=>1, "では"=>1, "を以て"=>1, "かぁ"=>1, "のう"=>1, "らしかっ"=>1, "そしたら"=>1, "にゃ"=>1, "まじ"=>1, "るる"=>1, "らし"=>1, "やん"=>1, "たけれ"=>1, "らしき"=>1, "しも"=>1, "べから"=>1, "或いは"=>1, "及び"=>1, "だが"=>1, "ごとき"=>1, "なし"=>1, "如き"=>1, "ねん"=>1, "但し"=>1, "ござる"=>1, "いえ"=>1, "故に"=>1, "即ち"=>1, "やっ"=>1, "なき"=>1, "無かっ"=>1, "なけりゃ"=>1, "即"=>1, "よって"=>1, "或は"=>1, "および"=>1, "尚"=>1, "否"=>1, "じゃろ"=>1, "っしょ"=>1, "尤も"=>1, "だに"=>1, "やす"=>1, "ござん"=>1, "ついで"=>1, "へん"=>1, "じゃっ"=>1, "わい"=>1, "次に"=>1, "之"=>1, "ける"=>1, "然し"=>1, "もっとも"=>1, "そうしたら"=>1, "無く"=>1, "やろ"=>1, "亦"=>1, "っし"=>1, "に対し"=>1, "乃至"=>1, "なれ"=>1, "御座る"=>1, "御座ん"=>1, "とう"=>1, "てえ"=>1, "但"=>1, "どし"=>1, "ざり"=>1, "といふ"=>1, "たれ"=>1, "したら"=>1, "もん"=>1, "やせ"=>1, "たくっ"=>1, "若しくは"=>1, "ずん"=>1, "あら"=>1, "ざれ"=>1, "無かろ"=>1, "無けれ"=>1, "ごとし"=>1, "たきゃ"=>1, "どす"=>1, "けり"=>1, "まじき"=>1, "ますれ"=>1, "たき"=>1, "てん"=>1, "たけりゃ"=>1, "無き"=>1, "無"=>1, "如し"=>1, "あん"=>1, "御座っ"=>1, "ありゃ"=>1, "かな"=>1, "ばかし"=>1,
      "a"=>1, "about"=>1, "after"=>1, "against"=>1, "all"=>1, "also"=>1, "although"=>1, "am"=>1, "among"=>1, "an"=>1, "and"=>1, "any"=>1, "anyone"=>1, "are"=>1, "as"=>1, "at"=>1, "ax"=>1, "be"=>1, "became"=>1, "because"=>1, "been"=>1, "being"=>1, "between"=>1, "but"=>1, "by"=>1, "c"=>1, "ca"=>1, "can"=>1, "come"=>1, "could"=>1, "cs"=>1, "did"=>1, "do"=>1, "does"=>1, "don"=>1, "during"=>1, "each"=>1, "early"=>1, "even"=>1, "for"=>1, "form"=>1, "found"=>1, "from"=>1, "get"=>1, "good"=>1, "had"=>1, "has"=>1, "have"=>1, "he"=>1, "her"=>1, "here"=>1, "him"=>1, "his"=>1, "how"=>1, "however"=>1, "i"=>1, "if"=>1, "in"=>1, "include"=>1, "including"=>1, "into"=>1, "is"=>1, "it"=>1, "its"=>1, "just"=>1, "know"=>1, "late"=>1, "later"=>1, "like"=>1, "made"=>1, "many"=>1, "may"=>1, "me"=>1, "more"=>1, "most"=>1, "much"=>1, "my"=>1, "near"=>1, "need"=>1, "new"=>1, "no"=>1, "non"=>1, "not"=>1, "now"=>1, "of"=>1, "off"=>1, "on"=>1, "one"=>1, "only"=>1, "or"=>1, "other"=>1, "our"=>1, "out"=>1, "over"=>1, "people"=>1, "please"=>1, "r"=>1, "right"=>1, "s"=>1, "same"=>1, "see"=>1, "several"=>1, "she"=>1, "should"=>1, "so"=>1, "some"=>1, "something"=>1, "such"=>1, "t"=>1, "than"=>1, "that"=>1, "the"=>1, "their"=>1, "them"=>1, "then"=>1, "there"=>1, "these"=>1, "they"=>1, "think"=>1, "this"=>1, "those"=>1, "through"=>1, "time"=>1, "to"=>1, "too"=>1, "u"=>1, "under"=>1, "until"=>1, "up"=>1, "us"=>1, "use"=>1, "used"=>1, "ve"=>1, "very"=>1, "want"=>1, "was"=>1, "way"=>1, "we"=>1, "well"=>1, "were"=>1, "what"=>1, "when"=>1, "where"=>1, "which"=>1, "who"=>1, "why"=>1, "will"=>1, "with"=>1, "would"=>1, "you"=>1, "your"=>1,
      "q" => 1, "p" => 1, "b" => 1, "d" => 1, "o" => 1, "8" => 1, "1" => 1, "0" => 1, "z"=>1, "w"=>1, "v" => 1, "7" => 1, "x" => 1, "e" => 1, "f" => 1, "c" => 1 ,"3" => 1
    }
  end
end
