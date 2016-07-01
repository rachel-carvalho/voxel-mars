#!/usr/bin/env sh

rm -rf out

mkdir -p out/js
mkdir out/css

echo 'browserify > uglify > timestamp > js...'
JS_TS=`stat -f "%Sm" -t "%Y%m%d%H%M%S" js/`
node_modules/.bin/browserify -t coffeeify js/index.coffee | node_modules/.bin/uglifyjs > out/js/index.$JS_TS.js

echo 'stylus > timestamp > css...'
CSS_TS=`stat -f "%Sm" -t "%Y%m%d%H%M%S" css/`
node_modules/.bin/stylus -c css/index.styl -p > out/css/index.$CSS_TS.css

echo 'pug > html...'
node_modules/.bin/pug -p html/index.pug -O "{css: 'index.$CSS_TS.css', js: 'index.$JS_TS.js'}" < html/index.pug > out/index.html

echo "copying files to out/"
cp -R static/ out/
cp -R world/static/ out/world/
cp -R world/out/ out/world/

echo 'done'
