#!/bin/bash

# wp.sh - Replaces wp core files

function rand_name {
    local dis_name="disabled-${RANDOM}"
    echo "$dis_name"
}

# Define
adm='wp-admin'
inc='wp-includes'
ind='index.php'
ver_php="$inc/version.php"

# Check for existing wp
if [ -f "$ver_php" ]; then
    ver="$(grep 'wp_version =' $ver_php | awk -F"'" '{print $2}')"
    echo -e "\nFound wp version $ver\n"
    read -p "Continue replacing wp $ver? (y/n) " ans1
    if [ "$ans1" != 'y' ]; then
        echo -e "\nExiting\n"
        exit 1
    fi
else
    echo -e "\n$ver_php not found\n"
    read -p "Enter wp version to install: " ver
fi

rel="wordpress-$ver"
url="https://wordpress.org/$rel.zip"

for i in "$adm" "$inc" wordpress; do
    if [ -d "$i" ]; then
        mv "$i" "$i-$(rand_name)"
    fi
done

wget "$url"
unzip "$rel.zip" && mv wordpress "$rel" && rm "$rel.zip"

echo -e "\nRestoring wp-admin..."
mv "$rel/$adm" "$adm"

echo "Restoring wp-includes..."
mv "$rel/$inc" "$inc"

# Verify user wants to write index.php and other wp php files
if [ -f "$ind" ]; then
    echo -e "\n$ind detected:"
    ls -lh "$ind"
    read -p "Continue replacing $ind and php files? (y/n) " ans2
    if [ "$ans2" == 'y' ]; then
        echo -e "\nRestoring php files..."
        mv "$ind" "$ind-$(rand_name)"
        cp -f "$rel"/*.php .
    else
        echo -e "\nExiting\n"
        exit 1
    fi
else
    echo "Restoring php files..."
    cp -f "$rel"/*.php .
fi

echo "Cleaning up..."
rm -rf "$rel"

echo -e "\nDone\n"

rm -- "$0"