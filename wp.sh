#!/bin/bash

# wp.sh - Replaces core WordPress files

rand_name() {
    local dis_name="disabled-${RANDOM}"
    echo "$dis_name"
}

htacheck() {
    hta='.htaccess'

    if [[ -f "$hta" ]]; then
        htperms=$(stat -c "%a" "$hta")

        if [[ "$htperms" -eq '000' || "$htperms" -eq '444' ]]; then
            echo -e "\n$hta perms suck:"
            ls -l "$hta"
            echo -e "\nChmodding .htaccess...\n"
            chmod 644 "$hta"
        fi
    fi

    if [[ ! -e "$hta" || ! -s "$hta" ]]; then
        echo -e "\nRestoring .htaccess...\n"
        # https://developer.wordpress.org/advanced-administration/server/web-server/httpd/
        cat << EOF > "$hta"
# BEGIN WordPress

RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]

# END WordPress
EOF
    fi
}

# Define
adm='wp-admin'
inc='wp-includes'
ind='index.php'
ver_php="$inc/version.php"

# Check for existing wp
if [[ -f "$ver_php" && -s "$ver_php" ]]; then
    ver="$(grep 'wp_version =' $ver_php | awk -F"'" '{print $2}')"
    echo -e "\nFound WordPress version $ver\n"
    read -p "Continue replacing wp $ver? (y/n) " ans1
    if [[ "$ans1" != 'y' ]]; then
        echo -e "\nExiting\n"
        exit 1
    fi
else
    echo -e "\n$ver_php not found or empty\n"
    read -p "Enter WordPress version to install: " ver
fi

rel="wordpress-$ver"
url="https://wordpress.org/$rel.zip"

for i in "$adm" "$inc" wordpress; do
    if [[ -d "$i" ]]; then
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
if [[ -f "$ind" ]]; then
    echo -e "\n$ind detected:"
    ls -lh "$ind"
    echo
    read -p "Continue replacing $ind and php files? (y/n) " ans2
    if [[ "$ans2" == 'y' ]]; then
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

htacheck

echo "Cleaning up..."
rm -rf "$rel"

echo -e "\nDone\n"

rm -- "$0"