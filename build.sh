#!/usr/bin/env sh

rm -rf out

mkdir -p out/js
mkdir out/css

echo 'browserify > uglify > timestamp > js...'
JS_TS=`stat -f "%Sm" -t "%Y%m%d%H%M%S" js/`
browserify -t coffeeify js/index.coffee | uglifyjs > out/js/index.$JS_TS.js

echo 'stylus > timestamp > css...'
CSS_TS=`stat -f "%Sm" -t "%Y%m%d%H%M%S" css/`
stylus -c css/index.styl -p > out/css/index.$CSS_TS.css

echo 'jade > html...'
jade -p html/index.jade -O "{css: 'index.$CSS_TS.css', js: 'index.$JS_TS.js'}" < html/index.jade > out/index.html

echo 'done'