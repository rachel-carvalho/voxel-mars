deploy: build upload clean

build:
	browserify -t coffeeify ./client/index.coffee | uglifyjs > ./public/js/index.js
	browserify -t coffeeify ./client/worker.coffee | uglifyjs > ./public/js/worker.js

upload:
	s3cmd sync --delete-removed --exclude '*.img' --exclude '.DS_Store' public/ s3://www.voxelmars.com/

upload-dry:
	s3cmd sync --dry-run --delete-removed --exclude '*.img' --exclude '.DS_Store' public/ s3://www.voxelmars.com/

NASA_URL = http://pds-geosciences.wustl.edu/mgs/mgs-m-mola-5-megdr-l3-v1/mgsl_300x/meg128
MAP_PATH = ./public/maps/mars/heightmap

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
	rm ./public/js/index.js ./public/js/worker.js

.PHONY: build, upload, deploy, upload-dry, download-map, slice-map, clean