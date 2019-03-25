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
    elif [ -f "$wp_path/wp-admin/about.php" ]; then
        installed_ver=$(grep -F 'sanitize_title(' "$wp_path/wp-admin/about.php" | awk -F"'" '{print $2}')
    else
        echo "ERROR: WordPress version not found"
        exiting
    fi
    echo "Found WordPress version $installed_ver at $wp_path"
}

api_call() {
    tmp_json="/tmp/wp-$installed_ver-checksums"

    echo "Downloading reference checksums..."

    if [[ "$(which python3)" =~ 'python3' ]]; then
        py_ver='3'
    else
        py_ver=''
    fi

    wget -qO- --user-agent='wp-md5.sh' "https://api.wordpress.org/core/checksums/1.0/?version=$installed_ver&locale=en_US" | "python${py_ver}" -m json.tool > "$tmp_json"
}

download() {
    tgz="wordpress-$installed_ver.tar.gz"
    url="https://wordpress.org/$tgz"
    md5=$(wget -qO- "$url.md5")

    if [ ! -f "/tmp/$tgz" ]; then
        echo "Downloading $tgz..."
        wget -q -c "$url" -O "/tmp/$tgz"
    fi

    sum=$(md5sum "/tmp/$tgz" | awk '{print $1}')

    if [ "$sum" != "$md5" ]; then
        echo "ERROR: MD5 of $tgz does not match"
        echo "Tar: $sum"
        echo "MD5: $md5"
        exiting
    fi

    tar xzf "/tmp/$tgz" -C /tmp/
    if [ -d "/tmp/$installed_ver" ]; then
        rm -rf "/tmp/$installed_ver"
    fi
    mv /tmp/wordpress "/tmp/$installed_ver"
}

compare_hashes() {
    echo "Comparing hashes..."

    for i in $(grep -v '{' "$tmp_json" | grep -v '}'); do
        reference_file=$(echo -n "$i" | awk -F'"' '{print $2}')
        reference_md5=$(echo -n "$i" | awk -F'"' '{print $4}')

        if [ "$verbose" -eq 1 ]; then
            echo "Checking $wp_path/$reference_file..."
        fi

        installed_md5=$(md5sum "$wp_path/$reference_file" 2>/dev/null | awk '{print $1}')

        if [ "$reference_md5" != "$installed_md5" ]; then
            echo
            echo "ALERT: MD5s for $reference_file do not match"
            echo "Reference file : $reference_md5"
            echo "Installed file : $installed_md5"
            echo
            echo "********************************************************************************"
            echo -e "\nDiff of $reference_file\n"
            diff "/tmp/$installed_ver/$reference_file" "$wp_path/$reference_file" 2>/dev/null
            echo
            echo "********************************************************************************"
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
    api_call
    download
    compare_hashes

    echo "Done"
}

#########################

if [ $# -ne 1 ]; then
    if [ $# -ne 2 ]; then
        help
        exit 1
    fi
fi

main "$@"
