# NekonekoGen

ネコでもテキスト分類器のRubyライブラリが生成できる便利ツール

## インストール

    % gem install nekoneko_gen

でインストールできます。

または Gemfile に次の行を追加して

    gem 'nekoneko_gen'

次のコマンドを実行。

    $ bundle

## 使い方の例 (1) ２ちゃんねるの投稿からどのスレッドの投稿か判定するライブラリを生成する

例として、２ちゃんねるに投稿されたデータから、投稿（レス）がどのスレッドのレスか判定するライブラリを生成してみます。

まず

    % gem install nekoneko_gen

でインストールします。
Ruby 1.8.7でも1.9.2でも動きますが1.9.2のほうが5倍くらい速いので1.9.2以降がおすすめです。
環境は、ここではUbuntuを想定しますが、Windowsでも使えます。（WindowsXP, ruby 1.9.3p0で確認）

データは僕が用意しているので、適当にdataというディレクトリを作ってダウンロードします。

    % mkdir data
    % cd data
    % wget -i http://www.udp.jp/misc/2ch_data/index1.txt
    % cd ..

でダウンロードされます。

いろいろダウンロードされますが、とりあえず、ドラクエ質問スレとラブプラス質問スレの2択にしようと思うので、以下のファイルを使用します。
これらを使って、入力された文章がドラクエ質問スレのレスか、ラブプラス質問スレのレスか判定するライブラリを生成します。

- dragon_quest.txt: ドラゴンクエストなんでも質問スレのデータ（約3万件)
- dragon_quest_test.txt: dragon_quest.txtからテスト用に500件抜いたレス（dragon_quest.txtには含まれない）
- dragon_quest_test2.txt: dragon_quest_test.txtの2レスを1行にしたデータ
- loveplus.txt: ラブプラス質問スレのデータ（約2.5万件)
- loveplus_test.txt: loveplus.txtからテスト用に500件抜いたレス
- loveplus_test2.txt: loveplus_test.txtの2レスを1行にしたデータ

入力データのフォーマットは、1カテゴリ1ファイル1行1データです。このデータの場合は、1レス中の改行コードを消して1行1レスにしてしています。
データの整備はアンカー（>>1のようなリンク）を消しただけなので、「サンクス」「死ぬ」「そうです」みたいなどう考えても分類無理だろみたいなデータも含まれています。また突然荒らしが登場してスレと関係ないクソレスを繰り返していたりもします。
 \*_test.txtと\*_test2.txtは生成されたライブラリの確認用です。*_test.txtのうちいくつ正解できるか数えるのに使います。*_test2.txtは、*_test.txtの2レスを1データにしたものです。２ちゃんの投稿は短すぎてうまく判定できないことが多いのでは？　と思うので、なら2レスあれば判定できるのか？　という確認用です。

### 生成してみる

    % nekoneko_gen -n game_thread_classifier data/dragon_quest.txt data/loveplus.txt

nekoneko_genというコマンドで生成します。
 -nで生成する分類器の名前を指定します。これは".rb"を付けてファイル名になるのと、キャピタライズしてモジュール名になります。生成先ディレクトリを指定したい場合は、直接ファイル名でも指定できます。
その後ろに分類（判定）したい種類ごとに学習用のファイルを指定します。最低2ファイルで、それ以上ならいくつでも指定できます。

ちょっと時間がかかるので、待ちます。2分くらい。

    % nekoneko_gen -n game_thread_classifier data/dragon_quest.txt data/loveplus.txt
    loading data/dragon_quest.txt... 37.0108s
    loading data/loveplus.txt... 37.5334s
    step   0... 0.893258, 4.2150s
    step   1... 0.936877, 1.8508s
    step   2... 0.948048, 1.3891s
    step   3... 0.954943, 1.3921s
    step   4... 0.959396, 1.1686s
    step   5... 0.962824, 1.3013s
    step   6... 0.964833, 1.1754s
    step   7... 0.966271, 1.1562s
    step   8... 0.967749, 1.2547s
    step   9... 0.968537, 1.1301s
    step  10... 0.969581, 1.1238s
    step  11... 0.970074, 1.2611s
    step  12... 0.970369, 1.1102s
    step  13... 0.971197, 0.9888s
    step  14... 0.972162, 1.2344s
    step  15... 0.972655, 1.0946s
    step  16... 0.973186, 1.0937s
    step  17... 0.973482, 1.1007s
    step  18... 0.973896, 1.0846s
    step  19... 0.973975, 1.0803s
    DRAGON_QUEST, LOVEPLUS : 86497 features
    done nyan!

終わったら -nで指定した名前のファイルにRubyのコードが生成されています。

    % ls -la
    ...
    -rw-r--r-- 1 ore users 5000504 2012-06-04 07:20 game_thread_classifier.rb
    ...

5MBくらいありますね。結構デカい。
このファイルには、GameThreadClassifier（指定した名前をキャピタライズしたもの）というModuleが定義されていて、self.predict(text)というメソッドを持っています。このメソッドに文字列を渡すと、予測結果としてGameThreadClassifier::DRAGON_QUESTかGameThreadClassifier::LOVEPLUSを返します。この定数名は、コマンドに指定したデータファイル名を大文字にしたものです。

### 試してみる

生成されたライブラリを使ってみましょう。
注意として、Ruby 1.8.7の場合は、$KCODEを'u'にしておかないと動きません。あと入力の文字コードもutf-8のみです。

    # coding: utf-8
    if (RUBY_VERSION < '1.9.0')
      $KCODE = 'u'
    end
    require './game_thread_classifier'
    require 'kconv'
    
    $stdout.sync = true
    loop do
      print "> "
      line = $stdin.readline.toutf8
      label = GameThreadClassifier.predict(line)
      puts "#{GameThreadClassifier::LABELS[label]}の話題です!!!"
    end

こんなコードを console.rb として作ります。
GameThreadClassifier.predictは予測されるクラスのラベル番号を返します。
GameThreadClassifier::LABELSには、ラベル番号に対応するラベル名が入っているので、これを表示してみます。

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

できてるっぽいですね。CTRL+DとかCTRL+Cとかで適当に終わります。

### 正解率を調べてみる

 \*_test.txt、\*_test2.txtの何%くらい正解できるか調べてみます。

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

引数に指定したファイルを1行ずつpredictに渡して、予測されたラベル番号の数を数えて、クラスごとに全体の何割かを表示するだけのコードです。
GameThreadClassifier.kは、クラス数（この場合、DRAGON_QUESTとLOVEPLUSで2）を返します。
    
    % ruby test.rb data/dragon_quest_test.txt
        DRAGON_QUEST: 0.924000
            LOVEPLUS: 0.076000

data/dragon_quest_test.txtには、ドラクエ質問スレのデータしかないので、すべて正解であれば、DRAGON_QUEST: 1.0になるはずです。
DRAGON_QUEST: 0.924000なので、92.4%は正解して、7.6%はラブプラスと間違えたことが分かります。
同じようにすべて試してみましょう。
    
    % ruby test.rb data/dragon_quest_test.txt
        DRAGON_QUEST: 0.924000
            LOVEPLUS: 0.076000
    % ruby test.rb data/loveplus_test.txt
        DRAGON_QUEST: 0.102000
            LOVEPLUS: 0.898000

    % ruby test.rb data/dragon_quest_test2.txt
        DRAGON_QUEST: 0.988000
            LOVEPLUS: 0.012000
    % ruby test.rb data/loveplus_test2.txt
        DRAGON_QUEST: 0.004016
            LOVEPLUS: 0.995984

ラブプラスはちょっと悪くて、89.8%くらいですね。平均すると、91%くらい正解しています。
また2レスで判定すると99%以上正解することが分かりました。2レスあれば、それがドラクエスレか、ラブプラススレか、ほとんど間違えることなく判定できるっぽいですね。

#### まとめ

ここまで読んでいただければ、どういうものか分かったと思います。
用意したデータファイルを学習して、指定した文字列がどのデータファイルのデータと似ているか判定するRubyライブラリを生成します。
生成されたライブラリは、Rubyの標準ライブラリ以外では、 json と bimyou_segmenter に依存しています。

    gem install json bimyou_segmenter

C Extensionが使えない環境だと、

    gem install json_pure bimyou_segmenter

とすれば、いろんな環境で生成したライブラリが使えるようになります。

### 他のファイルも試す

データは他に skyrim.txt (スカイリムの質問スレ）、mhf.txt (モンスターハンターフロンティアオンラインの質問スレ）を用意しているので、これらも学習できます。

    % nekoneko_gen -n game_thread_classifier data/dragon_quest.txt data/loveplus.txt data/skyrim.txt data/mhf.txt

単純に指定するファイルを増やすだけです。
生成されるコードも判定結果が増えただけなので、上で作ったconsole.rb、test.rbがそのまま使えます。

    % nekoneko_gen -n game_thread_classifier data/dragon_quest.txt data/loveplus.txt data/skyrim.txt data/mhf.txt
    loading data/dragon_quest.txt... 37.1598s
    loading data/loveplus.txt... 37.9838s
    loading data/skyrim.txt... 134.5455s
    loading data/mhf.txt... 72.3003s
    step   0... 0.882245, 19.6765s
    step   1... 0.922662, 14.9239s
    step   2... 0.932979, 14.5471s
    step   3... 0.939081, 13.0942s
    step   4... 0.943442, 12.2289s
    step   5... 0.947011, 12.7141s
    step   6... 0.950062, 12.0611s
    step   7... 0.952911, 11.9480s
    step   8... 0.955120, 11.3372s
    step   9... 0.956726, 11.8161s
    step  10... 0.958260, 11.1741s
    step  11... 0.959807, 11.1724s
    step  12... 0.960831, 11.6116s
    step  13... 0.961533, 11.0797s
    step  14... 0.962678, 10.4930s
    step  15... 0.963860, 11.4895s
    step  16... 0.964193, 10.9576s
    step  17... 0.965106, 11.4999s
    step  18... 0.965567, 10.2368s
    step  19... 0.966096, 10.8386s
    DRAGON_QUEST : 245796 features
    LOVEPLUS : 245796 features
    SKYRIM : 245796 features
    MHF : 245796 features
    done nyan!
    
    % ruby test.rb data/dragon_quest_test.txt
        DRAGON_QUEST: 0.864000
            LOVEPLUS: 0.040000
              SKYRIM: 0.062000
                 MHF: 0.034000
    % ruby test.rb data/loveplus_test.txt
        DRAGON_QUEST: 0.070000
            LOVEPLUS: 0.832000
              SKYRIM: 0.056000
                 MHF: 0.042000
    % ruby test.rb data/skyrim_test.txt
        DRAGON_QUEST: 0.046000
            LOVEPLUS: 0.038000
              SKYRIM: 0.860000
                 MHF: 0.056000
    % ruby test.rb data/mhf_test.txt
        DRAGON_QUEST: 0.042000
            LOVEPLUS: 0.022000
              SKYRIM: 0.056000
                 MHF: 0.880000
    
    % ruby test.rb data/dragon_quest_test2.txt
        DRAGON_QUEST: 0.968000
            LOVEPLUS: 0.012000
              SKYRIM: 0.008000
                 MHF: 0.012000
    % ruby test.rb data/loveplus_test2.txt
        DRAGON_QUEST: 0.000000
            LOVEPLUS: 0.991968
              SKYRIM: 0.008032
                 MHF: 0.000000
    % ruby test.rb data/skyrim_test2.txt
        DRAGON_QUEST: 0.004000
            LOVEPLUS: 0.008000
              SKYRIM: 0.976000
                 MHF: 0.012000
    % ruby test.rb data/mhf_test2.txt
        DRAGON_QUEST: 0.008032
            LOVEPLUS: 0.000000
              SKYRIM: 0.012048
                 MHF: 0.979920

1レスの場合は、選択肢が増えた分悪くなっています。平均すると正解は86%くらいでしょうか。2レスの場合は、まだ97%以上正解しています。


## 使い方の例 (2) 20 newsgroupsを試してみる


文書分類では、20newsgroupsというデータセットがよく使われるようなので、試してみました。
nekoneko_genは英語テキストにも対応しています。

http://people.csail.mit.edu/jrennie/20Newsgroups/

これは20種類のニュースグループに投稿された約2万件のドキュメントを含むデータセットです（学習用が1.1万件、確認用が7.5千件だった)。
ニュースグループというのは、メーリングリストで２ちゃんねるをやっている感じのものだと思います。
20種類の板に投稿されたレスをどの板の投稿か判定するマシンを学習します。


(注意: ここに書かれている作業用のコードはRuby1.9系でしか動きません)

### 最新のnekoneko_genにアップデート

まず

    % gem update nekoneko_gen

とアップデートします。(古いものは英語に対応していないかもしれません）
これを書いている時点の最新は0.4.1です。
入っていない場合は、

    % gem install nekoneko_gen

でインストールされます。

### データの準備

サイトを見ると何種類かありますけど、20news-bydate.tar.gz を使います。

    % wget http://people.csail.mit.edu/jrennie/20Newsgroups/20news-bydate.tar.gz
    % tar -xzvf 20news-bydate.tar.gz
    % ls 
    20news-bydate-test  20news-bydate-train

train用とtest用に分かれているらしいので、trainで学習して、testで確認します。
構造を見てみましょう。


    % ls 20news-bydate-train
    alt.atheism    comp.os.ms-windows.misc   comp.sys.mac.hardware  misc.forsale  rec.motorcycles     rec.sport.hockey  sci.electronics  sci.space               talk.politics.guns     talk.politics.misc
    comp.graphics  comp.sys.ibm.pc.hardware  comp.windows.x         rec.autos     rec.sport.baseball  sci.crypt         sci.med          soc.religion.christian  talk.politics.mideast  talk.religion.misc
    % ls  20news-bydate-train/comp.os.ms-windows.misc
    10000  9141  9159  9450  9468  9486  9506

20news-bydate-trainと20news-bydate-testの下に各カテゴリのディレクトリがあって、各カテゴリのディレクトリにドキュメントがファイルに分かれて入っているようです。

nekoneko_genは、1ファイル1カテゴリ1行1データの入力フォーマットなので、まずこんなスクリプトで変換します。

    # coding: utf-8
    # 20news-conv.rb
    require 'fileutils'
    require 'kconv'
    
    src = ARGV.shift
    dest = ARGV.shift
    unless (src && dest)
      warn "20news-conv.rb srcdir destdir\n"
      exit(-1)
    end
    
    FileUtils.mkdir_p(dest)
    data = Hash.new
    # 元データの各ファイルについて
    Dir.glob("#{src}/*/*").each do |file|
      if (File.file?(file))
        # root/category/nに分解
        root, category, n = file.split('/')[-3 .. -1]
        if (root && category && n)
          data[category] ||= []
          # ファイルの内容を改行をスペースに置き換えて(1行にして)カテゴリのデータに追加
          data[category] << NKF::nkf("-w", File.read(file)).gsub(/[\r\n]+/, ' ')
        end
      end
    end
    
    # 出力側で
    data.each do |k,v|
      # カテゴリ名.txtのファイルにデータを行単位で吐く
      path = File.join(dest, "#{k}.txt")
      File.open(path, "w") do |f|
        f.write v.join("\n")
      end
    end

train、testというディレクトリに変換。

    % ruby 20news-conv.rb 20news-bydate-train train
    % ruby 20news-conv.rb 20news-bydate-test test
    %
    % ls test
    alt.atheism.txt              comp.sys.ibm.pc.hardware.txt  misc.forsale.txt     rec.sport.baseball.txt  sci.electronics.txt  soc.religion.christian.txt  talk.politics.misc.txt
    comp.graphics.txt            comp.sys.mac.hardware.txt     rec.autos.txt        rec.sport.hockey.txt    sci.med.txt          talk.politics.guns.txt      talk.religion.misc.txt
    comp.os.ms-windows.misc.txt  comp.windows.x.txt            rec.motorcycles.txt  sci.crypt.txt           sci.space.txt        talk.politics.mideast.txt
    % head alt.atheism.txt

できてます。

### 学習

1コマンドです。ここまでの作業のことは忘れましょう。分類器の名前はnews20にしました。
trainの下を全部指定します。

    % nekoneko_gen -n news20 train/*

ちょっと時間かかります。

    % nekoneko_gen -n news20 train/*
    loading train/alt.atheism.txt... 11.2039s
    loading train/comp.graphics.txt... 10.0659s
    loading train/comp.os.ms-windows.misc.txt... 24.7611s
    loading train/comp.sys.ibm.pc.hardware.txt... 9.1767s
    loading train/comp.sys.mac.hardware.txt... 8.3413s
    loading train/comp.windows.x.txt... 13.9806s
    loading train/misc.forsale.txt... 6.8255s
    loading train/rec.autos.txt... 9.9041s
    loading train/rec.motorcycles.txt... 9.4798s
    loading train/rec.sport.baseball.txt... 9.9481s
    loading train/rec.sport.hockey.txt... 14.2056s
    loading train/sci.crypt.txt... 19.5707s
    loading train/sci.electronics.txt... 9.6204s
    loading train/sci.med.txt... 13.6632s
    loading train/sci.space.txt... 14.4867s
    loading train/soc.religion.christian.txt... 16.4918s
    loading train/talk.politics.guns.txt... 16.2433s
    loading train/talk.politics.mideast.txt... 21.8133s
    loading train/talk.politics.misc.txt... 16.2976s
    loading train/talk.religion.misc.txt... 10.4111s
    step   0... 0.953548, 58.1906s
    step   1... 0.970537, 47.1082s
    step   2... 0.980550, 41.9248s
    step   3... 0.985889, 37.6781s
    step   4... 0.989483, 35.0408s
    step   5... 0.991824, 33.8357s
    step   6... 0.993727, 30.1385s
    step   7... 0.995139, 29.5926s
    step   8... 0.996107, 29.3976s
    step   9... 0.997182, 27.9107s
    step  10... 0.997546, 27.1800s
    step  11... 0.998004, 26.4783s
    step  12... 0.998581, 26.7023s
    step  13... 0.998985, 25.9511s
    step  14... 0.999145, 24.7697s
    step  15... 0.999324, 24.7991s
    step  16... 0.999430, 24.8879s
    step  17... 0.999569, 24.7246s
    step  18... 0.999622, 25.2175s
    step  19... 0.999615, 23.5225s
    ALT_ATHEISM : 153334 features
    COMP_GRAPHICS : 153334 features
    COMP_OS_MS_WINDOWS_MISC : 153334 features
    COMP_SYS_IBM_PC_HARDWARE : 153334 features
    COMP_SYS_MAC_HARDWARE : 153334 features
    COMP_WINDOWS_X : 153334 features
    MISC_FORSALE : 153334 features
    REC_AUTOS : 153334 features
    REC_MOTORCYCLES : 153334 features
    REC_SPORT_BASEBALL : 153334 features
    REC_SPORT_HOCKEY : 153334 features
    SCI_CRYPT : 153334 features
    SCI_ELECTRONICS : 153334 features
    SCI_MED : 153334 features
    SCI_SPACE : 153334 features
    SOC_RELIGION_CHRISTIAN : 153334 features
    TALK_POLITICS_GUNS : 153334 features
    TALK_POLITICS_MIDEAST : 153334 features
    TALK_POLITICS_MISC : 153334 features
    TALK_RELIGION_MISC : 153334 features
    done nyan!

終わったらnews20.rbというRubyのライブラリが生成されています。

    % ls -la news20.rb
    -rw-r--r-- 1 ore users 66599221 2012-06-02 17:10 news20.rb

60MB以上あります。デカい。

### 確認

20カテゴリもあって前回のスクリプトで1カテゴリずつ見るのはきついので、一気に確認するスクリプトを書きました。


    # coding: utf-8
    # test.rb
    
    # 分類器を読み込む
    require './news20'
    
    # ファイル名をnekoneko_genが返すラベル名に変換する関数
    def label_name(file)
      File.basename(file, ".txt").gsub(/[\.\-]/, "_").upcase
    end
    
    count = 0
    correct = 0
    # 指定された各ファイルについて
    ARGV.each do |file|
      # ファイル名からラベル名を得る
      name = label_name(file)
      
      # ラベル名から正解ラベル（定数）に変換
      # (News20::LABELSにラベル番号順のラベル名があるので添え字位置を探す）
      correct_label = News20::LABELS.each_with_index.select{|v,i| v == name}.flatten.pop
      
      file_count = 0
      file_correct = 0
      # ファイルの各行データについて
      File.read(file).lines do |l|
        # 予測
        label = News20.predict(l)
        # ラベルが一致していたら
        if (label == correct_label)
          # 正解!!
          file_correct += 1
        end
        # データ数
        file_count += 1
      end
      correct += file_correct
      count += file_count
      # ファイルの内での正解率を表示  
      printf("%26s: %f\n", name, file_correct.to_f / file_count.to_f)
    end
    
    # 全体の正解率を表示  
    printf("\nAccuracy: %f\n", correct.to_f / count.to_f)

testの下を全部指定します。

    % ruby test.rb test/*
                   ALT_ATHEISM: 0.789969
                 COMP_GRAPHICS: 0.825193
       COMP_OS_MS_WINDOWS_MISC: 0.753807
      COMP_SYS_IBM_PC_HARDWARE: 0.778061
         COMP_SYS_MAC_HARDWARE: 0.867532
                COMP_WINDOWS_X: 0.815190
                  MISC_FORSALE: 0.902564
                     REC_AUTOS: 0.916667
               REC_MOTORCYCLES: 0.969849
            REC_SPORT_BASEBALL: 0.957179
              REC_SPORT_HOCKEY: 0.984962
                     SCI_CRYPT: 0.952020
               SCI_ELECTRONICS: 0.778626
                       SCI_MED: 0.881313
                     SCI_SPACE: 0.936548
        SOC_RELIGION_CHRISTIAN: 0.937186
            TALK_POLITICS_GUNS: 0.934066
         TALK_POLITICS_MIDEAST: 0.914894
            TALK_POLITICS_MISC: 0.616129
            TALK_RELIGION_MISC: 0.677291
    
    Accuracy: 0.866171

86.6%でした。

