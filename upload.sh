#!/usr/bin/env sh

zip() {
  echo "gzipping $1"
  gzip -9 $1
  mv $1.gz $1
}

upload() {
  echo "uploading $1"

  # index.*.css
  s3cmd sync $1 --add-header "Content-Encoding: gzip" --mime-type="text/css" --acl-public out/css/index.*.css s3://www.voxelmars.com/css/
  # index.*.js
  s3cmd sync $1 --add-header "Content-Encoding: gzip" --mime-type="application/javascript" --acl-public out/js/index.*.js s3://www.voxelmars.com/js/

  # index.html
  s3cmd sync $1 --add-header "Cache-Control: no-cache, no-store, must-revalidate" --add-header "Pragma: no-cache" --add-header "Expires: 0" --mime-type="text/html" --acl-public out/index.html s3://www.voxelmars.com/

  # sync /out
  s3cmd sync $1 --delete-removed --exclude '.DS_Store' out/ s3://www.voxelmars.com/
}

zip out/css/index.*.css
zip out/js/index.*.js

upload --dry-run

read -p "Continue? (y/N) " -n 1 -r

echo

if [[ $REPLY =~ ^[Yy]$ ]]
  then
  echo 'yep'
  upload
fi
