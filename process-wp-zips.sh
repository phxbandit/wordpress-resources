#!/bin/bash
# process-wp-zips.sh
for i in *.zip; do
    dir=$(unzip -l "$i" | head -4 | tail -1 | awk '{print $4}' | sed -e 's/\/$//')
    ver=$(echo -n "$i" | sed -e 's/wordpress-//' | sed -e 's/\.zip$//')
    echo "Processing $i..."
    unzip -q "$i" && mv "$dir" "$ver" && rm "$i"
done
