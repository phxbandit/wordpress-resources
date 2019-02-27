#!/bin/bash
# wp-gen-md5s.sh
# ./wp-gen-md5s.sh | tee wordpress-md5s
for i in $(ls); do
    if [[ ! "$i" =~ "wp-process-zips.sh" ]] && [[ ! "$i" =~ "wp-gen-md5s.sh" ]] && [[ ! "$i" =~ "wordpress-md5s" ]]; then
        find "$i" -type f -not -path "*wp-content*" | xargs md5sum
    fi
done
