#!/bin/bash
 
BASEDIR=$(dirname $0)
cd $BASEDIR
echo
ls
echo $BASEDIR
echo
rm -f *.pvr.ccz
rm -f *.plist

find . -name \*.png | sed 's/\.png//g' | \
  xargs -I % -n 1 TexturePacker %.png \
    --sheet %.pvr \
    --data %.plist \
    --algorithm Basic \
    --allow-free-size \
    --no-trim \
    --opt PVRTC4 \
    --dither-fs 
    # --flip-pvr 
rm -f *.plist
rm -f *.png

echo "执行完"