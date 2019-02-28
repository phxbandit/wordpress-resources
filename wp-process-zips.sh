#!/bin/bash
# wp-process-zips.sh
# phxbandit

help() {
    echo "wp-process-zips.sh - Downloads WordPress and generates MD5s for wp-md5.sh"
    echo "Usage: ./wp-process-zips.sh [-a|-d|-h|-p]"
    echo "  -a = All, download and process"
    echo "  -d = Download zips only"
    echo "  -h = This help"
    echo "  -p = Process, extract zips and generate MD5s"
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
    wpmd5s='wordpress-md5s'

    for j in *.zip; do
        dir=$(unzip -l "$j" | head -4 | tail -1 | awk '{print $4}' | sed -e 's/\/$//')
        ver=$(echo -n "$j" | sed -e 's/wordpress-//' | sed -e 's/\.zip$//')
        echo "Extracting $j..."
        unzip -q "$j" && mv "$dir" "$ver" && rm "$j"
    done

    echo "Generating MD5s..."
    for k in $(ls); do
        if [[ ! "$k" =~ 'wp-process-zips.sh' ]] && [[ ! "$k" =~ 'wordpress-release-urls.txt' ]] && [[ ! "$k" =~ "$wpmd5s" ]]; then
            find "$k" -type f -not -path "*wp-content*" | xargs md5sum >> "$wpmd5s"
        fi
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

echo "Done"
