deploy: build upload clean

JS_TS = `stat -f "%Sm" -t "%Y%m%d%H%M%S" client/`
CSS_TS=`stat -f "%Sm" -t "%Y%m%d%H%M%S" public/css/style.css`

build:
	browserify -t coffeeify ./client/index.coffee | uglifyjs | gzip -9 -c > ./public/js/index.$(JS_TS).js
	cp public/css/style.css public/css/style.$(CSS_TS).css
	sed -i '' -e 's/"\/css\/style.css"/"\/css\/style.'$(CSS_TS)'.css"/' ./public/index.html 
	sed -i '' -e 's/"\/js\/index.js"/"\/js\/index.'$(JS_TS)'.js"/' ./public/index.html 

upload:
	s3cmd sync --add-header "Cache-Control: no-cache, no-store, must-revalidate" --add-header "Pragma: no-cache" --add-header "Expires: 0" --acl-public public/index.html s3://www.voxelmars.com/
	s3cmd sync --add-header "Content-Encoding: gzip" --mime-type="application/javascript" --acl-public public/js/index.*.js s3://www.voxelmars.com/js/
	s3cmd sync --delete-removed --exclude 'style.css' --exclude 'index.js' --exclude '*.img' --exclude '.DS_Store' public/ s3://www.voxelmars.com/

upload-dry:
	s3cmd sync --dry-run --add-header "Cache-Control: no-cache, no-store, must-revalidate" --add-header "Pragma: no-cache" --add-header "Expires: 0" --acl-public public/index.html s3://www.voxelmars.com/
	s3cmd sync --dry-run --add-header "Content-Encoding: gzip" --mime-type="application/javascript" --acl-public public/js/index.*.js s3://www.voxelmars.com/js/
	s3cmd sync --dry-run --delete-removed --exclude 'style.css' --exclude 'index.js' --exclude '*.img' --exclude '.DS_Store' public/ s3://www.voxelmars.com/

NASA_URL = http://pds-geosciences.wustl.edu/mgs/mgs-m-mola-5-megdr-l3-v1/mgsl_300x/meg128
MAP_PATH = ./maps/mars/heightmap

download-map:
	curl $(NASA_URL)/megt88n000hb.img -o $(MAP_PATH)/x0y0.img
	curl $(NASA_URL)/megt88n090hb.img -o $(MAP_PATH)/x1y0.img
	curl $(NASA_URL)/megt88n180hb.img -o $(MAP_PATH)/x2y0.img
	curl $(NASA_URL)/megt88n270hb.img -o $(MAP_PATH)/x3y0.img
	curl $(NASA_URL)/megt44n000hb.img -o $(MAP_PATH)/x0y1.img
	curl $(NASA_URL)/megt44n090hb.img -o $(MAP_PATH)/x1y1.img
	curl $(NASA_URL)/megt44n180hb.img -o $(MAP_PATH)/x2y1.img
	curl $(NASA_URL)/megt44n270hb.img -o $(MAP_PATH)/x3y1.img
	curl $(NASA_URL)/megt00n000hb.img -o $(MAP_PATH)/x0y2.img
	curl $(NASA_URL)/megt00n090hb.img -o $(MAP_PATH)/x1y2.img
	curl $(NASA_URL)/megt00n180hb.img -o $(MAP_PATH)/x2y2.img
	curl $(NASA_URL)/megt00n270hb.img -o $(MAP_PATH)/x3y2.img
	curl $(NASA_URL)/megt44s000hb.img -o $(MAP_PATH)/x0y3.img
	curl $(NASA_URL)/megt44s090hb.img -o $(MAP_PATH)/x1y3.img
	curl $(NASA_URL)/megt44s180hb.img -o $(MAP_PATH)/x2y3.img
	curl $(NASA_URL)/megt44s270hb.img -o $(MAP_PATH)/x3y3.img

slice-map:
	coffee ./slice.coffee

clean:
	sed -i '' -e 's/"\/css\/style.'$(CSS_TS)'.css"/"\/css\/style.css"/' ./public/index.html 
	sed -i '' -e 's/"\/js\/index.'$(JS_TS)'.js"/"\/js\/index.js"/' ./public/index.html 
	rm ./public/js/index.*.js ./public/css/style.*.css

.PHONY: build, upload, deploy, upload-dry, download-map, slice-map, clean