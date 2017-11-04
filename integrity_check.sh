#!/bin/bash

checksums_init_file=checksums_init.txt
checksums_current_file=checksums_current.txt

build_checksums() {
    check_dir=$1
    target_file=$2

    find "$check_dir" -type f | xargs -d '\n' sha256sum > $target_file
}

compare_checksums() {
    check_dir=$1
    init_file=$2
    current_file=$3

    build_checksums $check_dir $current_file

    while read line; do
        
        current_checksum=$(echo $line | cut -d " " -f 1)
        filename=$(echo $line | cut -d " " -f 2-)
        orig_checksum=$(grep "^[[:xdigit:]]*[[:space:]]*$filename$" $init_file | cut -d " " -f 1) 

        #echo "** file: $filename, current checksum: $current_checksum, orig checksum: $orig_checksum"
        
        if [ "" = "$orig_checksum" ]; then
            echo "File \"$filename\" did not exist previously"
        else 
            if [ "$current_checksum" != "$orig_checksum" ]; then
                echo "Checksum of \"$filename\" changed (orig: $orig_checksum, current: $current_checksum)"
            fi
        fi
    done <$current_file 

    while read line; do
        filename=$(echo $line | cut -d " " -f 2-)

        current_entry=$(grep "^[[:xdigit:]]*[[:space:]]*$filename$" $current_file) || echo "File \"$filename\" does not exist any more"
    done <$init_file 
}

if [[ $# < 2 ]]; then
    echo -e "$(basename $0) - a minimalistic file integrity checking tool"
    echo
    echo -e "Usage: $(basename $0) <command> <directory>"
    echo -e "Commands:"
    echo -e "\tinit\tinitial calculation of checksums for directory"
    echo -e "\tcheck\tcompare current checksums to initial checksums"
    exit 0
fi

base_dir=$2
if [[ ! -d $base_dir ]]; then
    echo "\"$base_dir\" is not a directory - exiting..."
    exit 1
fi

cmd=$1
case $cmd in
    init)
       build_checksums $base_dir $checksums_init_file
       ;;
    check)
       compare_checksums $base_dir $checksums_init_file $checksums_current_file
       ;;       
    *)
       echo "Unknown command - exiting..."
       exit 1
esac
