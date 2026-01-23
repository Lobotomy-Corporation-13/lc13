#!/bin/bash
set -e
source dependencies.sh
echo "Downloading BYOND version $BYOND_MAJOR.$BYOND_MINOR"
curl --user-agent "lc13-ci/1.0 (Linux; curl/8; +https://github.com/Lobotomy-Corporation-13/lc13)" "https://lc13.net/temp-ci/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond.zip" -o C:/byond.zip
