#!/bin/bash -eu

<< COMMENT
The MIT License (MIT)
Copyright (c) 2019 Hidetaka Kamigaito

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
COMMENT

timestamp=`date +%Y%m%d%H`
rss_link="https://dumps.wikimedia.org/jawiki/latest/jawiki-latest-pages-articles.xml.bz2-rss.xml"
rootdir=${PWD}
datadir=${rootdir}/data/${timestamp}
rss_name=`basename ${rss_link}`
mecab_bin=${rootdir}/apps/mecab/bin/mecab
thread_size=8
vector_size=300
dicts="ipa neologd"

# Make data directory
if [ ! -e ${datadir} ]; then
    mkdir -p ${datadir}
fi

# Update mecab neologd dictionary
cd apps
rm -rf mecab-ipadic-neologd
git clone https://github.com/neologd/mecab-ipadic-neologd.git
cd mecab-ipadic-neologd
yes no |\
./bin/install-mecab-ipadic-neologd -n --asuser
cd ..

# Set dictionary paths
dict_ipa=${rootdir}/apps/mecab/lib/mecab/dic/ipadic
echo ${dict_ipa}
dict_neologd=${rootdir}/apps/mecab-ipadic-neologd/build/`ls -l ${rootdir}/apps/mecab-ipadic-neologd/build/ |rev |awk -F" " '{print $1}' |rev |head -n 2 |tail -n 1`
echo ${dict_neologd}

# Preserve dictionaries
cd ${datadir}
cp -r ${dict_ipa} ./
cp -r ${dict_neologd} ./
cd ..

# Download RSS
cd ${datadir}
wget ${rss_link} --no-check-certificate
cd ..

# Download articles
cd ${datadir}
article_file=`cat ${datadir}/${rss_name} |grep "href" |awk -F"\"" '{print $2}'`
echo ${article_file}
wget ${article_file} --no-check-certificate
cd ..

# Extract tokenized texts
cd ${datadir}
python ${rootdir}/apps/wikiextractor/WikiExtractor.py `basename ${article_file}`
cat text/*/* |\
gzip -c \
> jawiki.gz
cd ..

## IPA
cd ${datadir}
gzip -dc jawiki.gz |\
${mecab_bin} \
-Owakati \
-d ${dict_ipa} \
> ${datadir}/jawiki.ipa
cd ..

## Neologd
cd ${datadir}
gzip -dc jawiki.gz |\
mecab \
-Owakati \
-d ${dict_neologd} \
> ${datadir}/jawiki.neologd
cd ..

# Learn vectors
cd ${datadir}

## fastText
for suffix in ${dicts}; do
    ${rootdir}/apps/fastText/fasttext \
    skipgram \
    -input ${datadir}/jawiki.${suffix} \
    -output ${datadir}/jawiki.${suffix}.fasttext \
    -dim ${vector_size} \
    -thread ${thread_size} &
done
wait

## word2vec
for suffix in ${dicts}; do
    ${rootdir}/apps/word2vec/bin/word2vec \
        -train ${datadir}/jawiki.${suffix} \
        -output ${datadir}/jawiki.${suffix}.w2v.txt \
        -size ${vector_size} \
        -window 5 \
        -sample 1e-4 \
        -negative 5 \
        -hs 0 \
        -cbow 0 \
        -iter 3 \
        -threads ${thread_size} &
done
wait

## Glove
for suffix in ${dicts}; do
    # Create vocab
    cat ${datadir}/jawiki.${suffix} |\
    ${rootdir}/apps/GloVe/build/vocab_count \
    -min-count 5 \
    -verbose 2 \
    > ${datadir}/jawiki.${suffix}.vocab
    # Calculate coocurrence
    cat ${datadir}/jawiki.${suffix} |\
    ${rootdir}/apps/GloVe/build/cooccur \
    -vocab-file ${datadir}/jawiki.${suffix}.vocab \
    -verbose 2 \
    -window-size 15 \
    > ${datadir}/jawiki.${suffix}.cooc
    # Shuffle dataset
    cat ${datadir}/jawiki.${suffix}.cooc |\
    ${rootdir}/apps/GloVe/build/shuffle \
    -verbose 2 \
    > ${datadir}/jawiki.${suffix}.shuf.cooc
    # Learn vectors
    ${rootdir}/apps/GloVe/build/glove \
    -save-file ${datadir}/jawiki.${suffix}.glove \
    -input-file ${datadir}/jawiki.${suffix}.shuf.cooc \
    -vector-size ${vector_size} \
    -binary 2 \
    -vocab-file ${datadir}/jawiki.${suffix}.vocab \
    -threads ${thread_size} \
    -verbose 2 &
done
wait

## Compress tokenized texts
cd ${datadir}
gzip ${datadir}/jawiki.ipa
gzip ${datadir}/jawiki.neologd
for suffix in ${dicts}; do
    rm ${datadir}/jawiki.${suffix}.cooc
    rm ${datadir}/jawiki.${suffix}.shuf.cooc
done
rm -rf ${datadir}/text
cd ..

# Generate links

# word2vec
for suffix in ${dicts}; do
    python ${rootdir}/apps/retrofitting/extract_wp_category_links.py \
        --input_path ${datadir}/jawiki-20191201-pages-articles.xml.bz2 \
        --vector_path ${datadir}/jawiki.${suffix}.w2v.txt \
        --output_path ${datadir}/jawiki.${suffix}.category_links.w2v.txt
done

# fasttext
for suffix in ${dicts}; do
    python ${rootdir}/apps/retrofitting/extract_wp_category_links.py \
        --input_path ${datadir}/jawiki-20191201-pages-articles.xml.bz2 \
        --vector_path ${datadir}/jawiki.${suffix}.fasttext.vec \
        --output_path ${datadir}/jawiki.${suffix}.category_links.fasttext.txt
done

# GloVe
for suffix in ${dicts}; do
    python ${rootdir}/apps/retrofitting/extract_wp_category_links.py \
        --input_path ${datadir}/jawiki-20191201-pages-articles.xml.bz2 \
        --vector_path ${datadir}/jawiki.${suffix}.glove.txt \
        --output_path ${datadir}/jawiki.${suffix}.category_links.glove.txt
done

# Retrofit

# word2vec
for suffix in ${dicts}; do
    python ${rootdir}/apps/retrofitting/retrofit.py \
        -i ${datadir}/jawiki.${suffix}.w2v.txt \
        -l ${datadir}/jawiki.${suffix}.category_links.w2v.txt \
        -o ${datadir}/jawiki.${suffix}.category_links.retrofit.w2v.txt \
        -n 10 &
done
wait

# fasttext
for suffix in ${dicts}; do
    python ${rootdir}/apps/retrofitting/retrofit.py \
        -i ${datadir}/jawiki.${suffix}.fasttext.vec \
        -l ${datadir}/jawiki.${suffix}.category_links.fasttext.txt \
        -o ${datadir}/jawiki.${suffix}.category_links.retrofit.fasttext.txt \
        -n 10 &
done
wait

# GloVe
for suffix in ${dicts}; do
    python ${rootdir}/apps/retrofitting/retrofit.py \
        -i ${datadir}/jawiki.${suffix}.glove.txt \
        -l ${datadir}/jawiki.${suffix}.category_links.glove.txt \
        -o ${datadir}/jawiki.${suffix}.category_links.retrofit.glove.txt \
        -n 10 &
done
wait
