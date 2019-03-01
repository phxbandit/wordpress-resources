#!/bin/bash
# wp-md5.sh - Verifies integrity of core WordPress files
# phxbandit

IFS=$'\n'

exiting() {
    echo "Exiting"
    exit 1
}

help() {
    echo "wp-md5.sh - Verifies integrity of core WordPress files"
    echo "Usage: ./wp-md5.sh [-h|-v] /absolute/path/to/wordpress"
    echo "  -h = This help"
    echo "  -v = Verbose output"
}

find_wp_version() {
    wp_path=$(echo "$1" | sed -e 's#/$##')

    if [ -f "$wp_path/wp-includes/version.php" ]; then
        installed_ver=$(grep '$wp_version =' "$wp_path/wp-includes/version.php" | awk -F"= '" '{print $2}' | sed -e "s/';$//")
    elif [ -f "$wp_path/readme.html" ]; then
        installed_ver=$(grep 'Version ' "$wp_path/readme.html" | awk '{print $4}')
    else
        echo "ERROR: WordPress version not found"
        exiting
    fi
    echo "Found WordPress version $installed_ver at $wp_path"
}

download() {
    txt='wordpress-release-urls.txt'

    if [ ! -f "$txt" ]; then
        echo "Downloading WordPress release URLs..."
        wget -q -c "https://raw.githubusercontent.com/phxbandit/wordpress-resources/master/$txt"
    fi

    line=$(grep "wordpress-$installed_ver" "$txt")
    url=$(echo -n "$line" | awk -F',' '{print $1}')
    zip=$(echo -n "$url" | awk -F'/' '{print $4}')
    md5=$(echo -n "$line" | awk -F',' '{print $2}')

    echo "Downloading $zip..."
    wget -q -c "$url"
    sum=$(md5sum "$zip" | awk '{print $1}')

    if [ "$sum" != "$md5" ]; then
        echo "ERROR: MD5 of $zip does not match"
        echo "Zip: $sum"
        echo "MD5: $md5"
        exiting
    fi
}

gen_md5s() {
    wpmd5s="wordpress-${installed_ver}-md5s"

    echo "Extracting $zip..."
    dir=$(unzip -l "$zip" | head -4 | tail -1 | awk '{print $4}' | sed -e 's#/$##')
    unzip -q "$zip" && mv "$dir" "$installed_ver"
    #rm "$zip"

    echo "Generating reference MD5s..."
    find "$installed_ver" -type f -not -path "*wp-content*" | xargs md5sum >> "$wpmd5s"
}

compare_md5s() {
    for i in $(grep " $installed_ver/" "$wpmd5s"); do
        master_md5=$(echo "$i" | awk '{print $1}')
        master_file=$(echo "$i" | awk '{print $2}' | sed -e "s#^$installed_ver/##")

        if [ "$verbose" -eq 1 ]; then
            echo "Checking $wp_path/$master_file..."
        fi

        installed_md5=$(md5sum "$wp_path/$master_file" | awk '{print $1}')

        if [ "$master_md5" != "$installed_md5" ]; then
            echo
            echo "ALERT: MD5s for $master_file do not match"
            echo "Reference file:    $master_md5"
            echo "Installed file: $installed_md5"
            echo
        fi
    done
}

main() {
    verbose=0

    if [ "$1" = '-h' ]; then
        help
        exit 0
    elif [ "$1" = '-v' ]; then
        verbose=1
        abs_path="$2"
    else
        abs_path="$1"
    fi

    find_wp_version "$abs_path"
    download
    gen_md5s
    compare_md5s
}

#########################################

# Handle prereqs
if [ "$(which unzip)" = '' ]; then
    echo "ERROR: unzip command not found"
    exiting
fi

if [ $# -ne 1 ]; then
    if [ $# -ne 2 ]; then
        help
        exit 1
    fi
fi

main "$@"

echo "Done"
