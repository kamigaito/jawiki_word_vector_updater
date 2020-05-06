#!/bin/bash -eu
ROOTDIR=${PWD}
cd apps
git clone https://github.com/dav/word2vec.git
git clone https://github.com/stanfordnlp/GloVe.git
git clone https://github.com/facebookresearch/fastText.git
git clone https://github.com/kamigaito/rf4wpc.git
git clone https://github.com/taku910/mecab.git
git clone https://github.com/neologd/mecab-ipadic-neologd.git 
git clone https://github.com/attardi/wikiextractor.git
cd word2vec
make build
cd ../GloVe
make
cd ../fastText
make
cd ../mecab/mecab
./configure --prefix=${ROOTDIR}/apps/mecab --with-charset=utf8
make
make install
cd ../mecab-ipadic
./configure --prefix=${ROOTDIR}/apps/mecab --with-mecab-config=${ROOTDIR}/apps/mecab/bin/mecab-config --with-charset=utf8
make
make install
cd ../../mecab-ipadic-neologd
yes no |\
./bin/install-mecab-ipadic-neologd -n --asuser
