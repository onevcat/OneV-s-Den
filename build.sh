#!/bin/sh
./tools/build.sh
rm _site/config.codekit3 _site/build.sh_site/Brewfile _site/Brewfile.lock.json
rsync -auv _site onevcat@onevcat.com:/home/onevcat/www/blog