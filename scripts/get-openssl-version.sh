#!/bin/bash
function get_openssl_version() {
    local std_version=$1
    local script_version=${2:-}
    local generic_version=${std_version%?}
    local subpatch=${std_version: -1}
    local subpatch_number=$(($(printf '%d' \'$subpatch) - 97 + 1))
    subpatch_number="$(printf '%02d' $subpatch_number)"
    script_version="$(printf '%02d' $script_version)"
    local normalized_version="${generic_version}${subpatch_number}${script_version}"
    echo $normalized_version
}
