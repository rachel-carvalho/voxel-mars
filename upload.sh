#!/usr/bin/env sh

zip () {
  gzip -9 $1
  mv $1.gz $1
}

zip out/css/index.*.css
zip out/js/index.*.js
zip out/index.html

# upload static/ to /
# upload out/ to /
# upload world/static to /world
# upload world/out to /world

# sync () {
#   s3cmd sync $1
# }

# index.html
# s3cmd sync --add-header "Cache-Control: no-cache, no-store, must-revalidate" --add-header "Pragma: no-cache" --add-header "Expires: 0" --acl-public public/index.html s3://www.voxelmars.com/

# index.*.js
# s3cmd sync --add-header "Content-Encoding: gzip" --mime-type="application/javascript" --acl-public public/js/index.*.js s3://www.voxelmars.com/js/

# public/
# s3cmd sync --delete-removed --exclude 'style.css' --exclude 'index.js' --exclude '*.img' --exclude '.DS_Store' public/ s3://www.voxelmars.com/

# dry
# s3cmd sync --dry-run --add-header "Cache-Control: no-cache, no-store, must-revalidate" --add-header "Pragma: no-cache" --add-header "Expires: 0" --acl-public public/index.html s3://www.voxelmars.com/
# s3cmd sync --dry-run --add-header "Content-Encoding: gzip" --mime-type="application/javascript" --acl-public public/js/index.*.js s3://www.voxelmars.com/js/
# s3cmd sync --dry-run --delete-removed --exclude 'style.css' --exclude 'index.js' --exclude '*.img' --exclude '.DS_Store' public/ s3://www.voxelmars.com/