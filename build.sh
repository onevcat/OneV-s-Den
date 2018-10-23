#!/bin/sh
bundle exec jekyll build
rm _site/config.codekit3 _site/build.sh
rsync -auv _site onevcat@160.16.135.145:/home/onevcat/www/blog