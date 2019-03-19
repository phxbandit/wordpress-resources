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
        wget -qO- --user-agent='wp-md5.sh' "https://api.wordpress.org/core/checksums/1.0/?version=$installed_ver&locale=en_US" | python3 -m json.tool > "$tmp_json"
    else
        wget -qO- --user-agent='wp-md5.sh' "https://api.wordpress.org/core/checksums/1.0/?version=$installed_ver&locale=en_US" | python -m json.tool > "$tmp_json"
    fi
}

compare_hashes() {
    echo "Comparing hashes..."

    for i in $(grep -v '{' "$tmp_json" | grep -v '}'); do
        master_file=$(echo -n "$i" | awk -F'"' '{print $2}')
        master_md5=$(echo -n "$i" | awk -F'"' '{print $4}')

        if [ "$verbose" -eq 1 ]; then
            echo "Checking $wp_path/$master_file..."
        fi

        installed_md5=$(md5sum "$wp_path/$master_file" 2>/dev/null | awk '{print $1}')

        if [ "$master_md5" != "$installed_md5" ]; then
            echo
            echo "ALERT: MD5s for $master_file do not match"
            echo "Reference file : $master_md5"
            echo "Installed file : $installed_md5"
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
