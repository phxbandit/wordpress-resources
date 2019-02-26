#!/bin/bash

# wpmd5.sh - Compares wordpress.org md5s to installed wp md5s
# phxbadit

# Process zips
# #!/bin/bash
#
# # convert-zips.sh
#
# for i in *.zip; do
#     ver=$(echo "$i" | awk -F"-" '{print $2}' | sed -e 's/\.zip$//')
#     unzip "$i"
#     mv wordpress "$ver"
#     rm "$i"
# done

# Generate MD5s
# #!/bin/bash
#
# # ./create-md5s.sh | tee wordpress-md5s
#
# for i in $(ls); do
#     if [[ ! "$i" =~ "convert-zips.sh" ]] && [[ ! "$i" =~ "create-md5s.sh" ]] && [[ ! "$i" =~ "wordpress-md5s" ]]; then
#         find "$i" -type f -not -path "*wp-content*" | xargs md5sum
#     fi
# done

IFS=$'\n'

# Help
usage() {
    echo
    echo "Usage: ./wpmd5.sh [-v] /absolute/path/to/wordpress"
    echo "   -v: Verbose output"
    echo
    exit 1
}

# Handle arguments
if [ $# -ne 1 ]; then
    if [ $# -ne 2 ]; then
        usage
    fi
fi

verbose=0

if [ "$1" = '-v' ]; then
    verbose=1
    wp_path_tmp="$2"
else
    wp_path_tmp="$1"
fi

# Define md5 file
wpmd5s='wordpress-md5s.gz'

# Check for md5sum
if [ "$(which md5sum)" = '' ]; then
    echo "ERROR: md5sum command not found... exiting"
    exit 1
fi

# Verify wp exists
wp_path=$(echo $wp_path_tmp | sed -e 's#/$##')
[ -f "$wp_path/wp-config.php" ] || usage

# Find wp version
if [ -f "$wp_path/wp-includes/version.php" ]; then
    installed_ver=$(grep 'wp_version =' "$wp_path/wp-includes/version.php" | awk -F"= '" '{print $2}' | sed -e "s/';$//")
elif [ -f "$wp_path/readme.html" ]; then
    installed_ver=$(grep 'Version ' "$wp_path/readme.html" | awk '{print $4}')
else
    echo "ERROR: WordPress version unavailable... exiting"
    exit 1
fi
echo
echo "Found WordPress version $installed_ver at $wp_path"
echo

# Compare md5s
for i in $(zgrep " $installed_ver/" "$wpmd5s"); do
    master_md5=$(echo "$i" | awk '{print $1}')
    master_file=$(echo "$i" | awk '{print $2}' | sed -e "s#$installed_ver/##")

    installed_md5=$(md5sum "$wp_path/$master_file" | awk '{print $1}')

    if [ "$verbose" -eq 1 ]; then
        echo "Checking $wp_path/$master_file"
    fi

    if [ "$master_md5" != "$installed_md5" ]; then
        echo
        echo "ALERT: MD5s for $master_file do not match"
        echo "Master file:    $master_md5"
        echo "Installed file: $installed_md5"
        echo
    fi
done

echo
echo "Complete"
echo
