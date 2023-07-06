#!/bin/bash

# wp.sh - Replaces wp core files

# Todo: make random name creation a function

# Define
adm='wp-admin'
inc='wp-includes'
ind='index.php'
verphp="$inc/version.php"

# Check for existing wp
if [ -f "$verphp" ]; then
    ver="$(grep 'wp_version =' $verphp | awk -F"'" '{print $2}')"
    echo -e "\nFound wp version $ver\n"
    read -p "Continue replacing wp $ver? (y/n) " ans1
    if [ "$ans1" != 'y' ]; then
        echo -e "\nExiting\n"
        exit
    fi
else
    echo -e "\n$verphp not found\n"
    read -p "Enter wp version to install: " ver
fi

rel="wordpress-$ver"
url="https://wordpress.org/$rel.zip"

if [ -d "$adm" ]; then
    dis1="DISABLED${RANDOM}"
    mv "$adm" "$adm-$dis1"
fi

if [ -d "$inc" ]; then
    dis2="DISABLED${RANDOM}"
    mv "$inc" "$inc-$dis2"
fi

if [ -d 'wordpress' ]; then
    dis3="DISABLED${RANDOM}"
    mv wordpress "wordpress-$dis3"
fi

wget "$url"
unzip "$rel.zip" && mv wordpress "$rel" && rm "$rel.zip"

echo "Restoring wp-admin..."
mv "$rel/$adm" "$adm"

echo "Restoring wp-includes..."
mv "$rel/$inc" "$inc"

# Verify user wants to write index.php and other wp php files
if [ -f "$ind" ]; then
    lslh=$(ls -lh "$ind")
    echo -e "\n$ind detected:"
    echo -e "$lslh\n"
    read -p "Continue replacing $ind and php files? (y/n) " ans2
    if [ "$ans2" == 'y' ]; then
        echo -e "\nRestoring php files..."
        dis4="DISABLED${RANDOM}"
        mv "$ind" "$ind-$dis4"
        cp -f "$rel"/*.php .
    else
        echo -e "\nExiting\n"
        exit
    fi
else
    echo "Restoring php files..."
    cp -f "$rel"/*.php .
fi

echo "Cleaning up..."
rm -rf "$rel"

echo -e "\nDone\n"

rm -- "$0"