#!/bin/bash
# wp-process-zips.sh
# phxbandit

help() {
    echo "wp-process-zips.sh - Downloads and processes WordPress zips for wp-md5.sh"
    echo "Usage: ./wp-process-zips.sh [-a|-d|-h|-p]"
    echo "  -a = All, download and process"
    echo "  -d = Download zips only"
    echo "  -h = This help"
    echo "  -p = Process zips only"
}

download() {
    urls='wordpress-release-urls.txt'

    if [ -f "$urls" ]; then
        txt="$urls"
    elif [ -f "$HOME/$urls" ]; then
        txt="$HOME/$urls"
    else
        txt="$urls"
        wget -q "https://raw.githubusercontent.com/phxbandit/wordpress-resources/master/$urls"
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

if [ $# -ne 1 ]; then
    help
    exit 1
fi

while getopts :adhp opt; do
    case $opt in
        a) download
           process
        ;;
        d) download
        ;;
        h) help
           exit 0
        ;;
        p) process
        ;;
        \?) help
            exit 1
        ;;
    esac
done
