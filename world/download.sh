#!/usr/bin/env sh

mkdir src
mkdir src/navigation
mkdir src/height

curl http://marsoweb.nas.nasa.gov/globalData/images/fullscale/MOLA_cylin.jpg -o src/navigation/navigation.jpg

download () {
  curl http://pds-geosciences.wustl.edu/mgs/mgs-m-mola-5-megdr-l3-v1/mgsl_300x/meg128/$1.img -o src/height/$2.img
}

download megt88n000hb x0y0
download megt88n090hb x1y0
download megt88n180hb x2y0
download megt88n270hb x3y0
download megt44n000hb x0y1
download megt44n090hb x1y1
download megt44n180hb x2y1
download megt44n270hb x3y1
download megt00n000hb x0y2
download megt00n090hb x1y2
download megt00n180hb x2y2
download megt00n270hb x3y2
download megt44s000hb x0y3
download megt44s090hb x1y3
download megt44s180hb x2y3
download megt44s270hb x3y3