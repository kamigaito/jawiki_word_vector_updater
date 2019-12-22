# jawiki word vector updater

最新の[日本語Wikipediaのダンプデータ](https://dumps.wikimedia.org/jawiki/)から，[MeCab](http://taku910.github.io/mecab/)を用いて[IPA辞書](https://github.com/taku910/mecab/tree/master/mecab-ipadic)と最新の[Neologd辞書](https://github.com/neologd/mecab-ipadic-neologd/blob/master/README.ja.md)の両方で形態素解析を実施し，その結果に基づいた
[word2vec]()，[fastText]()，[GloVe](https://nlp.stanford.edu/projects/glove/)の単語分散表現を学習するためのスクリプト

取得されたダンプデータと学習された単語ベクトルは``data/YYYYmmddHH``，例：``data/2019021212``のような年月日時の名前を持つディレクトリにまとめて保存される．
使用した形態素解析辞書についても再現性確保のために，同様のディレクトリに保存される．

## 実行に必要なコマンド・パッケージ類
- bash
- git
- diff
- wget
- curl
- python 3.x

## 使い方

### セットアップ

```
./scripts/setup.sh
```

実行後，下記パッケージが``apps``ディレクトリ以下にビルドされる．
- [mecab](https://github.com/taku910/mecab)
- [mecab-ipadic](https://github.com/taku910/mecab)
- [mecab-ipadic-neologd](https://github.com/neologd/mecab-ipadic-neologd)
- [word2vec](https://github.com/dav/word2vec)
- [GloVe](https://github.com/stanfordnlp/GloVe)
- [fastText](https://github.com/facebookresearch/fastText)
- [WikiExtractor](https://github.com/attardi/wikiextractor)

### 単語ベクトルの学習

#### 手動で更新を行う場合

```
./scripts/update.sh
```

ダンプデータの取得と単語ベクトルの学習を一貫して行うため，実行には多くの時間を要する．家庭用デスクトップPCで実行した場合は1日ほどかかる．
実行後に以下のファイル・ディレクトリが``data/YYYYmmddHH``以下に出力される
- ``jawiki-YYYYmmdd-pages-articles.xml.bz2`` : ダウンロードされたWikipedia記事ダンプデータ
- ``jawiki-latest-pages-articles.xml.bz2-rss.xml`` : ダウンロードされたWikipedia記事ダンプデータのRSS
- ``ipadic`` : 形態素解析で使用されたIPA辞書
- ``mecab-ipadic-2.7.0-20070801-neologd-YYYYmmdd`` : 形態素解析で使用されたNeologd
- ``jawiki.gz`` : タグなどが除去されたWikipedia記事ダンプデータ
- ``jawiki.ipa.gz`` : IPA辞書による形態素解析実行後のWikipedia記事ダンプデータ
- ``jawiki.neologd.gz`` : Neologd辞書による形態素解析実行後のWikipedia記事ダンプデータ
- ``jawiki.ipa.w2v.bin`` : IPA辞書を用いた形態素解析結果から学習されたword2vecのモデル出力
- ``jawiki.ipa.fasttext.bin`` : IPA辞書を用いた形態素解析結果から学習されたfastTextのモデル出力
- ``jawiki.ipa.fasttext.vec`` : IPA辞書を用いた形態素解析結果から学習されたfastTextのモデル出力
- ``jawiki.ipa.glove.bin`` : IPA辞書を用いた形態素解析結果から学習されたGloVeのモデル出力
- ``jawiki.ipa.vocab`` : IPA辞書を用いた形態素解析結果から学習されたGloVeの語彙辞書
- ``jawiki.neologd.w2v.bin`` : Neologd辞書を用いた形態素解析結果から学習されたword2vecのモデル出力
- ``jawiki.neologd.fasttext.bin`` : Neologd辞書を用いた形態素解析結果から学習されたfastTextのモデル出力
- ``jawiki.neologd.fasttext.vec`` : Neologd辞書を用いた形態素解析結果から学習されたfastTextのモデル出力
- ``jawiki.neologd.glove.bin`` : Neologd辞書を用いた形態素解析結果から学習されたGloVeのモデル出力
- ``jawiki.neologd.vocab`` : Neologd辞書を用いた形態素解析結果から学習されたGloVeの語彙辞書

#### 現在の単語ベクトルが最新のWikipediaダンプデータに基づいているかを確認する場合

```
./scripts/rss_check.sh
```

最新ならばY，最新でなければNが標準出力に表示される．

#### cronで定期更新を行う場合

``./scripts/cron.sh``をcronに登録すればよい．

## License
MIT
