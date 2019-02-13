#!/bin/bash

<< COMMENT
The MIT License (MIT)
Copyright (c) 2019 Hidetaka Kamigaito

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
COMMENT

rootdir=${PWD}
datadir=${rootdir}/data
rss_link="https://dumps.wikimedia.org/jawiki/latest/jawiki-latest-pages-articles.xml.bz2-rss.xml"
latest_timestamp=`ls -lv ${datadir} |head -n 2 |tail -n 1|rev |awk -F" " '{print $1}' |rev`
latest_rss=${datadir}/${latest_timestamp}/`basename ${rss_link}`
if diff <(wget -O - ${rss_link}) ${latest_rss}; then
    echo "Y"
else
    echo "N"
fi
