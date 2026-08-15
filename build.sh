#!/usr/bin/env bash

set -euo pipefail

bash tools/build.sh
rsync -auv _site onevcat@onevcat.com:/home/onevcat/www/blog
