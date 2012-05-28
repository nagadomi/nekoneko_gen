# NekonekoGen

Easy to Use Ruby Text Classifier Generator.

## Installation

Add this line to your application's Gemfile:

    gem 'nekoneko_gen'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nekoneko_gen

## Usage

    % mkdir data
    % cd data
    % wget -i http://www.udp.jp/misc/2ch_data/index1.txt
    ...
    % cd ..
    % nekoneko_gen -n game_thread_classifier data/dragon_quest.txt data/loveplus.txt
    loading data/dragon_quest.txt... 35.5426s
    loading data/loveplus.txt... 36.0522s
    step   0... 0.879858, 3.7805s
    step   1... 0.919624, 2.2018s
    step   2... 0.932147, 2.1174s
    step   3... 0.940959, 2.0569s
    step   4... 0.946985, 1.8876s
    step   5... 0.950891, 1.8564s
    step   6... 0.953541, 1.8398s
    step   7... 0.955464, 1.8204s
    step   8... 0.957427, 1.8008s
    step   9... 0.959056, 1.7912s
    step  10... 0.961098, 1.8027s
    step  11... 0.961745, 1.7716s
    step  12... 0.962943, 1.7633s
    step  13... 0.963610, 1.7477s
    step  14... 0.964611, 1.6216s
    step  15... 0.965259, 1.7291s
    step  16... 0.965730, 1.7271s
    step  17... 0.966613, 1.7225s
    step  18... 0.967241, 1.5861s
    step  19... 0.967712, 1.7113s
    DRAGON_QUEST, LOVEPLUS : 71573 features
    done nyan!
    
    % ls -la
    ...
    -rw-r--r--  1 ore users 2555555 2012-05-28 08:10 game_thread_classifier.rb
    ...
    
    % cat > console.rb
    # coding: utf-8
    if (RUBY_VERSION < '1.9.0')
      $KCODE = 'u'
    end
    require './game_thread_classifier'
    
    $stdout.sync = true
    loop do
      print "> "
      line = $stdin.readline
      label = GameThreadClassifier.predict(line)
      puts "#{GameThreadClassifier::LABELS[label]}の話題です!!!"
    end
    ^D
    
    % ruby console.rb
    > 彼女からメールが来た
    LOVEPLUSの話題です!!!
    > 日曜日はデートしてました
    LOVEPLUSの話題です!!!
    > 金欲しい
    DRAGON_QUESTの話題です!!!
    > 王様になりたい
    DRAGON_QUESTの話題です!!!
    > スライム
    DRAGON_QUESTの話題です!!!
    > スライムを彼女にプレゼント
    LOVEPLUSの話題です!!!
    
    %cat > test.rb
    if (RUBY_VERSION < '1.9.0')
      $KCODE = 'u'
    end
    require './game_thread_classifier'
    
    labels = Array.new(GameThreadClassifier.k, 0)
    file = ARGV.shift
    File.open(file) do |f|
      until f.eof?
        l = f.readline.chomp
        label = GameThreadClassifier.predict(l)
        labels[label] += 1
      end
    end
    count = labels.reduce(:+)
    labels.each_with_index do |c, i|
      printf "%16s: %f\n", GameThreadClassifier::LABELS[i], c.to_f / count.to_f
    end
    ^D
    
    % ruby test.rb data/dragon_quest_test.txt
        DRAGON_QUEST: 0.932000
            LOVEPLUS: 0.068000
    % ruby test.rb data/loveplus_test.txt
        DRAGON_QUEST: 0.124000
            LOVEPLUS: 0.876000
    % ruby test.rb data/dragon_quest_test2.txt
        DRAGON_QUEST: 0.988000
            LOVEPLUS: 0.012000
    % ruby test.rb data/loveplus_test2.txt
        DRAGON_QUEST: 0.012048
            LOVEPLUS: 0.987952
    
    
    % nekoneko_gen -n game_thread_classifier data/dragon_quest.txt data/loveplus.txt data/skyrim.txt data/mhf.txt
    ...
    ...
    ...

