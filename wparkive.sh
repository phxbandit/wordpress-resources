#!/bin/bash
# wparkive.sh

if [ $# -ne 1 ]; then
    echo "Use: wparkive <x.x.x>"
    exit
fi

ver="$1"
rel="wordpress-$ver"
url="https://wordpress.org/$rel.zip"
ark="$HOME/releases-wp"

if [ -d "$ark/$rel" ]; then
    echo "release exists"
    exit
fi

wget "$url"

unzip "$rel.zip" && mv wordpress "$ark/$rel" && rm "$rel.zip"

echo "done"