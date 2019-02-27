#!/bin/bash
# process-wp-zips.sh
# phxbandit

help() {
    echo "process-wp-zips.sh - Downloads and processes WordPress zips for wpmd5.sh"
    echo "Usage: ./process-wp-zips.sh [-d|-h|-p]"
    echo "  -d = Download zips only"
    echo "  -h = This help"
    echo "  -p = Process zips only"
    exit 1
}

download() {
    urls='wp-release-urls.txt'

    if [ -f "$urls" ]; then
        txt="$urls"
    elif [ -f "$HOME/$urls" ]; then
        txt="$HOME/$urls"
    else
        txt="$urls"
        wget -q https://raw.githubusercontent.com/phxbandit/wordpress-resources/master/wp-release-urls.txt
    fi

    for i in $(cat "$txt"); do
        url=$(echo -n "$i" | awk -F',' '{print $1}')
        zip=$(echo -n "$url" | awk -F'/' '{print $4}')
        md5=$(echo -n "$i" | awk -F',' '{print $2}')

        echo "Downloading $zip..."
        wget -q "$url"
        sum=$(md5sum "$zip" | awk '{print $1}')

        if [ "$sum" != "$md5" ]; then
            echo "ERROR: MD5 of $zip does not match:"
            echo "$sum != $md5"
            echo "Exiting"
            exit 1
        fi
    done
}

process() {
    for j in *.zip; do
        dir=$(unzip -l "$j" | head -4 | tail -1 | awk '{print $4}' | sed -e 's/\/$//')
        ver=$(echo -n "$j" | sed -e 's/wordpress-//' | sed -e 's/\.zip$//')
        echo "Processing $j..."
        unzip -q "$j" && mv "$dir" "$ver" && rm "$j"
    done
}

if [ $# -gt 1 ]; then
    help
fi

if [ "$1" = '-h' ]; then
    help
elif [ "$1" = '-d' ]; then
    download
elif [ "$1" = '-p' ]; then
    process
else
    download
    process
fi
